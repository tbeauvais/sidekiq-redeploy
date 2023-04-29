# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidekiq::Redeploy::Loader do
  subject(:loader) { described_class.new(signal_mod: signal, process_mod: process, signal_delay: 0, loop_delay: 0) }

  let(:sidekiq_pid) { 456 }
  let(:loader_pid) { 123 }
  let(:signal) { class_double(Signal, trap: nil) }
  let(:process) { class_double(Process,  pid: loader_pid, getpgid: 0, kill: true) }

  before do
    allow(loader).to receive(:exit_loader).and_return(true)
    allow(loader).to receive(:process_died?).and_return(false)
    allow(loader).to receive(:log)
  end

  describe '#run' do
    it 'adds trap for signals' do
      allow(process).to receive(:fork).and_return(sidekiq_pid)
      %w[INT TERM USR2 TTIN].each { |sig| expect(signal).to receive(:trap).with(sig) }
      loader.run
    end

    it 'forks process' do
      expect(process).to receive(:fork).and_return(sidekiq_pid)
      loader.run
    end

    context 'when sidekiq process has died' do
      it 'restarts sidekiq process' do
        allow(loader).to receive(:process_died?).and_return(true)
        expect(loader).to receive(:fork_sidekiq).twice.and_return(sidekiq_pid)
        loader.run
      end
    end

    context 'when reloading sidekiq' do
      it 'sends quite and shutdown signals to sidekiq process' do
        allow(process).to receive(:fork).and_return(sidekiq_pid)
        allow(loader).to receive(:reload_sidekiq).and_return(true)
        expect(process).to receive(:kill).with('TSTP', sidekiq_pid)
        expect(process).to receive(:kill).with('TERM', sidekiq_pid)
        loader.run
      end

      it 'forks sidekiq process' do
        allow(loader).to receive(:reload_sidekiq).and_return(true)
        expect(process).to receive(:fork).twice.and_return(sidekiq_pid)
        loader.run
      end
    end
  end
end
