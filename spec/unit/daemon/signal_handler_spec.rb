require 'unit_spec_helper'

describe Rpush::Daemon::SignalHandler do
  describe 'shutdown signals' do
    # These tests do not work on JRuby.
    unless Rpush.jruby?
      it "shuts down when signaled signaled SIGINT" do
        Rpush::Daemon::SignalHandler.start
        Rpush::Daemon.should_receive(:shutdown)
        Process.kill("SIGINT", Process.pid)
        sleep 0.01
        Rpush::Daemon::SignalHandler.stop
      end

      it "shuts down when signaled signaled SIGTERM" do
        Rpush::Daemon::SignalHandler.start
        Rpush::Daemon.should_receive(:shutdown)
        Process.kill("SIGTERM", Process.pid)
        sleep 0.01
        Rpush::Daemon::SignalHandler.stop
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
end
