# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/cli'

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

      def initialize(signal_mod: Signal, process_mod: Process, signal_delay: 1, loop_delay: 0.5)
        @reload_sidekiq = false
        @exit_loader = false
        @loader_pid = Process.pid
        @signal_mod = signal_mod
        @process_mod = process_mod
        @signal_delay = signal_delay
        @loop_delay = loop_delay
      end

      def run
        log "Starting sidekiq reloader... pid=#{process_mod.pid}"

        trap_signals

        fork_sidekiq

        process_loop

        log 'Waiting for Sidekiq process to end'
        Process.waitall

        log 'Shutting down sidekiq reloader'
      rescue StandardError => e
        log "Error in sidekiq loader: #{e.message}"
        log e.backtrace.join("\n")
        exit 1
      end

      private

      attr_reader :signal_mod, :process_mod, :exit_loader, :reload_sidekiq, :signal_delay, :loop_delay

      def process_loop
        loop do
          sleep(loop_delay)
          if reload_sidekiq
            stop_sidekiq(@sidekiq_pid)
            fork_sidekiq
            @reload_sidekiq = false
          elsif process_died?(@sidekiq_pid)
            fork_sidekiq
          end
          next unless exit_loader

          stop_sidekiq(@sidekiq_pid)
          break
        end
      end

      def fork_sidekiq
        @sidekiq_pid = process_mod.fork do
          cli = Sidekiq::CLI.instance
          cli.parse
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
          signal_mod.trap(signal) do
            handle_signal(signal)
          end
        end
      end

      # There are limitations as to what to can do in a signal trap handler
      # See https://github.com/ruby/ruby/blob/ruby_3_2/doc/signals.rdoc
      def handle_signal(signal)
        debug_handler(signal)
        # Our handle_signal gets called for child processes (i.e. sidekiq process) so we don't want to re-handle these.
        return if @loader_pid != process_mod.pid

        case signal
        when USR2
          @reload_sidekiq = true
        when TTIN
          process_mod.kill(signal, @sidekiq_pid)
        when TERM, INT
          log 'About to exit'
          @exit_loader = true
        end
      end

      def debug_handler(signal)
        log_data = { signal:, current_pid: process_mod.pid, loader_pid: @loader_pid, sidekiq_pid: @sidekiq_pid,
                     reload_sidekiq: @reload_sidekiq, exit_loader: @exit_loader }
        log "handle_signal called with #{log_data}"
      end

      def stop_sidekiq(pid)
        log "Sending TSTP signal to #{pid}"
        process_mod.kill(TSTP, pid)
        sleep signal_delay
        log "Sending TERM signal to #{pid}"
        process_mod.kill(TERM, pid)
      end

      def process_died?(pid)
        !process_mod.getpgid(pid)
      rescue StandardError
        true
      end

      def log(message)
        $stdout.puts message
      end
    end
  end
end
