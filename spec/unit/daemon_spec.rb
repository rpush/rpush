require 'unit_spec_helper'

describe Rapns::Daemon, "when starting" do
  module Rails; end

  let(:certificate) { stub }
  let(:password) { stub }
  let(:config) { stub(:pid_file => nil, :airbrake_notify => false,
    :foreground => true, :embedded => false, :push => false) }
  let(:logger) { stub(:logger, :info => nil, :error => nil, :warn => nil) }

  before do
    Rapns.stub(:config => config)
    Rapns::Logger.stub(:new => logger)
    Rapns::Daemon::Feeder.stub(:start)
    Rapns::Daemon::AppRunner.stub(:sync => nil, :stop => nil)
    Rapns::Daemon.stub(:daemonize => nil, :reconnect_database => nil, :exit => nil, :puts => nil)
    File.stub(:open)
    Rails.stub(:root).and_return("/rails_root")
  end

  unless defined?(JRUBY_VERSION)
    it "forks into a daemon if the foreground option is false" do
      config.stub(:foreground => false)
      ActiveRecord::Base.stub(:establish_connection)
      Rapns::Daemon.should_receive(:daemonize)
      Rapns::Daemon.start
    end

    it "does not fork into a daemon if the foreground option is true" do
      config.stub(:foreground => true)
      Rapns::Daemon.should_not_receive(:daemonize)
      Rapns::Daemon.start
    end

    it "does not fork into a daemon if the push option is true" do
      config.stub(:push => true)
      Rapns::Daemon.should_not_receive(:daemonize)
      Rapns::Daemon.start
    end

    it "does not fork into a daemon if the embedded option is true" do
      config.stub(:embedded => true)
      Rapns::Daemon.should_not_receive(:daemonize)
      Rapns::Daemon.start
    end
  end

  it 'sets up setup signal traps' do
    Rapns::Daemon.should_receive(:setup_signal_traps)
    Rapns::Daemon.start
  end

  it 'does not setup signal traps when embedded' do
    config.stub(:embedded => true)
    Rapns::Daemon.should_not_receive(:setup_signal_traps)
    Rapns::Daemon.start
  end

  it "writes the process ID to the PID file" do
    Rapns::Daemon.should_receive(:write_pid_file)
    Rapns::Daemon.start
  end

  it "logs an error if the PID file could not be written" do
    config.stub(:pid_file => '/rails_root/rapns.pid')
    File.stub(:open).and_raise(Errno::ENOENT)
    logger.should_receive(:error).with("Failed to write PID to '/rails_root/rapns.pid': #<Errno::ENOENT: No such file or directory>")
    Rapns::Daemon.start
  end

  it "starts the feeder" do
    Rapns::Daemon::Feeder.should_receive(:start)
    Rapns::Daemon.start
  end

  it "syncs apps" do
    Rapns::Daemon::AppRunner.should_receive(:sync)
    Rapns::Daemon.start
  end
end

describe Rapns::Daemon, "when being shutdown" do
  let(:config) { stub(:pid_file => '/rails_root/rapns.pid') }

  before do
    Rapns.stub(:config => config)
    Rapns::Daemon.stub(:puts => nil)
    Rapns::Daemon::Feeder.stub(:stop)
    Rapns::Daemon::AppRunner.stub(:stop)
  end

  # These tests do not work on JRuby.
  unless defined? JRUBY_VERSION
    it "shuts down when signaled signaled SIGINT" do
      Rapns::Daemon.setup_signal_traps
      Rapns::Daemon.should_receive(:shutdown)
      Process.kill("SIGINT", Process.pid)
    end

    it "shuts down when signaled signaled SIGTERM" do
      Rapns::Daemon.setup_signal_traps
      Rapns::Daemon.should_receive(:shutdown)
      Process.kill("SIGTERM", Process.pid)
    end
  end

  it "stops the feeder" do
    Rapns::Daemon::Feeder.should_receive(:stop)
    Rapns::Daemon.shutdown
  end

  it "stops the app runners" do
    Rapns::Daemon::AppRunner.should_receive(:stop)
    Rapns::Daemon.shutdown
  end

  it "removes the PID file if one was written" do
    File.stub(:exists?).and_return(true)
    File.should_receive(:delete).with("/rails_root/rapns.pid")
    Rapns::Daemon.shutdown
  end

  it "does not attempt to remove the PID file if it does not exist" do
    File.stub(:exists?).and_return(false)
    File.should_not_receive(:delete)
    Rapns::Daemon.shutdown
  end

  it "does not attempt to remove the PID file if one was not written" do
    config.stub(:pid_file).and_return(nil)
    File.should_not_receive(:delete)
    Rapns::Daemon.shutdown
  end
end
