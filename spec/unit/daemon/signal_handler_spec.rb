require 'unit_spec_helper'

describe Rpush::Daemon::SignalHandler do
  def signal_handler(sig)
    Process.kill(sig, Process.pid)
    sleep 0.1
  end

  def with_handler_start_stop
    Rpush::Daemon::SignalHandler.start
    yield
  ensure
    Rpush::Daemon::SignalHandler.stop
  end

  describe 'shutdown signals' do
    unless Rpush.jruby? # These tests do not work on JRuby.
      it "shuts down when signaled signaled SIGINT" do
        with_handler_start_stop do
          Rpush::Daemon.should_receive(:shutdown)
          signal_handler('SIGINT')
        end
      end

      it "shuts down when signaled signaled SIGTERM" do
        with_handler_start_stop do
          Rpush::Daemon.should_receive(:shutdown)
          signal_handler('SIGTERM')
        end
      end
    end
  end

  describe 'config.embedded = true' do
    before { Rpush.config.embedded = true }

    it 'does not trap signals' do
      Signal.should_not_receive(:trap)
      Rpush::Daemon::SignalHandler.start
    end
  end

  describe 'HUP' do
    before do
      Rpush::Daemon::Synchronizer.stub(:sync)
      Rpush::Daemon::Feeder.stub(:wakeup)
    end

    it 'syncs' do
      with_handler_start_stop do
        Rpush::Daemon::Synchronizer.should_receive(:sync)
        signal_handler('HUP')
      end
    end

    it 'wakes up the Feeder' do
      with_handler_start_stop do
        Rpush::Daemon::Feeder.should_receive(:wakeup)
        signal_handler('HUP')
      end
    end
  end

  describe 'USR2' do
    it 'instructs the AppRunner to print debug information' do
      with_handler_start_stop do
        Rpush::Daemon::AppRunner.should_receive(:debug)
        signal_handler('USR2')
      end
    end
  end

  describe 'error handing' do
    let(:error) { StandardError.new('test') }

    before { Rpush.stub(logger: double(error: nil, info: nil)) }

    it 'logs errors received when handling a signal' do
      Rpush::Daemon::Synchronizer.stub(:sync).and_raise(error)
      expect(Rpush.logger).to receive(:error).with(error)
      with_handler_start_stop do
        signal_handler('HUP')
      end
    end

    it 'does not interrupt processing of further errors' do
      Rpush::Daemon::Synchronizer.stub(:sync).and_raise(error)
      expect(Rpush::Daemon::AppRunner).to receive(:debug)
      with_handler_start_stop do
        signal_handler('HUP')
        signal_handler('USR2')
      end
    end
  end
end
