# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/cli'
require 'logger'

module Sidekiq
  module Redeploy
    # Loads sidekiq process and monitors for redeploy
    class Loader
      USR2 = 'USR2' # Signal to sidekiq redeploy loader to restart a new Sidekiq process
      TTIN = 'TTIN' # Signal to sidekiq to print backtraces for all threads
      TSTP = 'TSTP' # Signal to sidekiq that it will be shutting down soon and it should stop taking jobs.
      TERM = 'TERM' # Signal to shutdown the loader after shutdown of sidekiq process
      INT  = 'INT'  # Signal to shutdown the loader after shutdown of sidekiq process

      SIGNALS = [INT, TERM, USR2, TTIN].freeze

      def initialize(deployer:, sidekiq_app: nil, logger: Logger.new($stdout), config: {})
        @reload_sidekiq = false
        @exit_loader = false
        @loader_pid = Process.pid
        @logger = logger
        @signal_delay = config[:signal_delay] || 1
        @watch_delay = config[:watch_delay] || 30
        @watch_time = Time.now
        @loop_delay = config[:loop_delay] || 0.5
        @deployer = deployer
        @sidekiq_app = sidekiq_app
      end

      def run
        log "Starting sidekiq reloader... pid=#{@loader_pid}"

        trap_signals

        fork_sidekiq

        process_loop

        log 'Waiting for Sidekiq process to end'
        Process.waitall

        log 'Shutting down sidekiq reloader'
      rescue StandardError => e
        log "Error in sidekiq loader: #{e.message}"
        log e.backtrace.join("\n")
        stop_sidekiq(@sidekiq_pid)
        Process.waitall
        exit 1
      end

      private

      attr_reader :exit_loader, :reload_sidekiq, :signal_delay, :loop_delay, :deployer, :logger

      def process_loop
        loop do
          sleep(loop_delay)
          if needs_redeploy?
            reload_app { deployer.deploy(source: deployer.archive_file) }
          elsif reload_sidekiq
            reload_app
          elsif process_died?(@sidekiq_pid)
            fork_sidekiq
          end
          next unless exit_loader

          stop_sidekiq(@sidekiq_pid)
          break
        end
      end

      def needs_redeploy?
        return unless (Time.now - @watch_time) > @watch_delay

        @watch_time = Time.now
        log 'Checking watch file for redeploy'
        deployer.needs_redeploy?
      end

      def reload_app
        quiet_sidekiq(@sidekiq_pid)

        yield if block_given?

        stop_sidekiq(@sidekiq_pid)

        # wait for sidekiq to stop
        Process.waitall

        fork_sidekiq
        @reload_sidekiq = false
      end

      def fork_sidekiq
        @sidekiq_pid = Process.fork do
          cli = Sidekiq::CLI.instance
          args = @sidekiq_app ? ['-r', @sidekiq_app] : []
          cli.parse(args)
          cli.run
        rescue StandardError => e
          message "Error loading sidekiq process: #{e.message}"
          log message
          log e.backtrace.join("\n")
          raise message
        end
      end

      def trap_signals
        SIGNALS.each do |signal|
          Signal.trap(signal) do
            handle_signal(signal)
          end
        end
      end

      # There are limitations as to what to can do in a signal trap handler
      # See https://github.com/ruby/ruby/blob/ruby_3_2/doc/signals.rdoc
      def handle_signal(signal)
        debug_handler(signal)
        # Our handle_signal gets called for child processes (i.e. sidekiq process) so we don't want to re-handle these.
        return if @loader_pid != Process.pid

        case signal
        when USR2
          @reload_sidekiq = true
        when TTIN
          Process.kill(signal, @sidekiq_pid)
        when TERM, INT
          @exit_loader = true
        end
      end

      def debug_handler(signal)
        log_data = { signal:, current_pid: Process.pid, loader_pid: @loader_pid, sidekiq_pid: @sidekiq_pid,
                     reload_sidekiq: @reload_sidekiq, exit_loader: @exit_loader }
        puts "handle_signal called with #{log_data}"
      end

      def stop_sidekiq(pid)
        Process.kill(TERM, pid) if pid
      end

      def quiet_sidekiq(pid)
        Process.kill(TSTP, pid) if pid
      end

      def process_died?(pid)
        return false if @exit_loader

        !Process.getpgid(pid)
      rescue StandardError
        true
      end

      def log(message)
        logger&.info message
      end
    end
  end
end
