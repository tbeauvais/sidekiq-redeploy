# frozen_string_literal: true

require 'spec_helper'
require 'puma-redeploy'

RSpec.describe Sidekiq::Redeploy::Loader do
  subject(:loader) { described_class.new(deployer:, logger:, config:) }

  let(:sidekiq_pid) { 456 }
  let(:loader_pid) { 123 }
  let(:config) { { signal_delay: 0, loop_delay: 0 } }
  let(:deployer) do
    instance_double(Puma::Redeploy::FileHandler, needs_redeploy?: false, deploy: 0, archive_file: 'test.zip',
                                                 watch_file: 'ttt')
  end
  let(:logger) { instance_double(Logger, info: nil) }

  before do
    allow(Signal).to receive(:trap)
    allow(Process).to receive(:kill)
    allow(loader).to receive_messages(exit_loader: true, process_died?: false)
  end

  describe '#run' do
    it 'adds trap for signals' do
      allow(Process).to receive(:fork).and_return(sidekiq_pid)
      %w[INT TERM USR2 TTIN].each { |sig| expect(Signal).to receive(:trap).with(sig) }
      loader.run
    end

    it 'forks process' do
      expect(Process).to receive(:fork).and_return(sidekiq_pid)
      loader.run
    end

    context 'when sidekiq process has died' do
      it 'restarts sidekiq process' do
        allow(loader).to receive(:process_died?).and_return(true)
        allow(Process).to receive(:kill)
        expect(loader).to receive(:fork_sidekiq).twice.and_return(sidekiq_pid)
        loader.run
      end
    end

    context 'when reloading sidekiq' do
      it 'sends quite and shutdown signals to sidekiq process' do
        allow(Process).to receive(:fork).and_return(sidekiq_pid)
        allow(loader).to receive(:reload_sidekiq).and_return(true)
        expect(Process).to receive(:kill).once.with('TSTP', sidekiq_pid)
        expect(Process).to receive(:kill).twice.with('TERM', sidekiq_pid)
        loader.run
      end

      it 'forks sidekiq process' do
        allow(loader).to receive(:reload_sidekiq).and_return(true)
        expect(Process).to receive(:fork).twice.and_return(sidekiq_pid)
        loader.run
      end
    end
  end
end
