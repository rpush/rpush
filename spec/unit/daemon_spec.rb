require 'unit_spec_helper'
require 'rpush/daemon/store/active_record'

describe Rpush::Daemon, "when starting" do
  module Rails; end

  let(:certificate) { double }
  let(:password) { double }
  let(:config) { double(:pid_file => nil, :foreground => true,
    :embedded => false, :push => false, :client => :active_record,
    :logger => nil) }
  let(:logger) { double(:logger, :info => nil, :error => nil, :warn => nil) }

  before do
    Rpush.stub(:config => config, :logger => logger)
    Rpush::Daemon::Feeder.stub(:start)
    Rpush::Daemon::AppRunner.stub(:sync => nil, :stop => nil)
    Rpush::Daemon.stub(:daemonize => nil, :exit => nil, :puts => nil)
    File.stub(:open)
  end

  unless Rpush.jruby?
    it "forks into a daemon if the foreground option is false" do
      config.stub(:foreground => false)
      Rpush::Daemon.initialize_store
      Rpush::Daemon.store.stub(:after_daemonize => nil)
      Rpush::Daemon.should_receive(:daemonize)
      Rpush::Daemon.start
    end

    it 'notifies the store after forking' do
      config.stub(:foreground => false)
      Rpush::Daemon.initialize_store
      Rpush::Daemon.store.should_receive(:after_daemonize)
      Rpush::Daemon.start
    end

    it "does not fork into a daemon if the foreground option is true" do
      config.stub(:foreground => true)
      Rpush::Daemon.should_not_receive(:daemonize)
      Rpush::Daemon.start
    end

    it "does not fork into a daemon if the push option is true" do
      config.stub(:push => true)
      Rpush::Daemon.should_not_receive(:daemonize)
      Rpush::Daemon.start
    end

    it "does not fork into a daemon if the embedded option is true" do
      config.stub(:embedded => true)
      Rpush::Daemon.should_not_receive(:daemonize)
      Rpush::Daemon.start
    end
  end

  it 'sets up setup signal traps' do
    Rpush::Daemon.should_receive(:setup_signal_traps)
    Rpush::Daemon.start
  end

  it 'does not setup signal traps when embedded' do
    config.stub(:embedded => true)
    Rpush::Daemon.should_not_receive(:setup_signal_traps)
    Rpush::Daemon.start
  end

  it 'instantiates the store' do
    config.stub(:client => :active_record)
    Rpush::Daemon.start
    Rpush::Daemon.store.should be_kind_of(Rpush::Daemon::Store::ActiveRecord)
  end

  it 'logs an error if the store cannot be loaded' do
    config.stub(:client => :foo_bar)
    Rpush.logger.should_receive(:error).with(kind_of(LoadError))
    Rpush::Daemon.start
  end

  it "writes the process ID to the PID file" do
    Rpush::Daemon.should_receive(:write_pid_file)
    Rpush::Daemon.start
  end

  it "logs an error if the PID file could not be written" do
    config.stub(:pid_file => '/rails_root/rpush.pid')
    File.stub(:open).and_raise(Errno::ENOENT)
    logger.should_receive(:error).with("Failed to write PID to '/rails_root/rpush.pid': #<Errno::ENOENT: No such file or directory>")
    Rpush::Daemon.start
  end

  it "starts the feeder" do
    Rpush::Daemon::Feeder.should_receive(:start)
    Rpush::Daemon.start
  end

  it "syncs apps" do
    Rpush::Daemon::AppRunner.should_receive(:sync)
    Rpush::Daemon.start
  end
end

describe Rpush::Daemon, "when being shutdown" do
  let(:config) { double(:pid_file => '/rails_root/rpush.pid') }
  let(:logger) { double(:info => nil, :error => nil, :warn => nil) }

  before do
    Rpush.stub(:config => config)
    Rpush::Daemon.stub(:puts => nil)
    Rpush::Daemon::Feeder.stub(:stop)
    Rpush::Daemon::AppRunner.stub(:stop)
  end

  # These tests do not work on JRuby.
  unless Rpush.jruby?
    it "shuts down when signaled signaled SIGINT" do
      Rpush::Daemon.setup_signal_traps
      Rpush::Daemon.should_receive(:shutdown)
      Process.kill("SIGINT", Process.pid)
      sleep 0.01
    end

    it "shuts down when signaled signaled SIGTERM" do
      Rpush::Daemon.setup_signal_traps
      Rpush::Daemon.should_receive(:shutdown)
      Process.kill("SIGTERM", Process.pid)
      sleep 0.01
    end
  end

  it "stops the feeder" do
    Rpush::Daemon::Feeder.should_receive(:stop)
    Rpush::Daemon.shutdown
  end

  it "stops the app runners" do
    Rpush::Daemon::AppRunner.should_receive(:stop)
    Rpush::Daemon.shutdown
  end

  it "removes the PID file if one was written" do
    File.stub(:exists?).and_return(true)
    File.should_receive(:delete).with("/rails_root/rpush.pid")
    Rpush::Daemon.shutdown
  end

  it "does not attempt to remove the PID file if it does not exist" do
    File.stub(:exists?).and_return(false)
    File.should_not_receive(:delete)
    Rpush::Daemon.shutdown
  end

  it "does not attempt to remove the PID file if one was not written" do
    config.stub(:pid_file).and_return(nil)
    File.should_not_receive(:delete)
    Rpush::Daemon.shutdown
  end
end
