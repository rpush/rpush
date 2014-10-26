require 'unit_spec_helper'
require 'rpush/daemon/store/active_record'

describe Rpush::Daemon, "when starting" do
  module Rails; end

  let(:certificate) { double }
  let(:password) { double }
  let(:logger) { double(:logger, info: nil, error: nil, warn: nil) }

  before do
    Rpush.stub(logger: logger)
    Rpush::Daemon::Feeder.stub(:start)
    Rpush::Daemon::Synchronizer.stub(sync: nil)
    Rpush::Daemon::AppRunner.stub(stop: nil)
    Rpush::Daemon.stub(exit: nil, puts: nil)
    Rpush::Daemon::SignalHandler.stub(start: nil, stop: nil, handle_shutdown_signal: nil)
    Process.stub(:daemon)
    File.stub(:open)
  end

  unless Rpush.jruby?
    it "forks into a daemon if the foreground option is false" do
      Rpush.config.foreground = false
      Rpush::Daemon.common_init
      Process.should_receive(:daemon)
      Rpush::Daemon.start
    end

    it "does not fork into a daemon if the foreground option is true" do
      Rpush.config.foreground = true
      Process.should_not_receive(:daemon)
      Rpush::Daemon.start
    end

    it "does not fork into a daemon if the push option is true" do
      Rpush.config.push = true
      Process.should_not_receive(:daemon)
      Rpush::Daemon.start
    end

    it "does not fork into a daemon if the embedded option is true" do
      Rpush.config.embedded = true
      Process.should_not_receive(:daemon)
      Rpush::Daemon.start
    end
  end

  it 'releases the store connection' do
    Rpush::Daemon.store = double
    Rpush::Daemon.store.should_receive(:release_connection)
    Rpush::Daemon.start
  end

  it 'sets up setup signal traps' do
    Rpush::Daemon::SignalHandler.should_receive(:start)
    Rpush::Daemon.start
  end

  it 'instantiates the store' do
    Rpush.config.client = :active_record
    Rpush::Daemon.start
    Rpush::Daemon.store.should be_kind_of(Rpush::Daemon::Store::ActiveRecord)
  end

  it 'initializes plugins' do
    plugin = Rpush.plugin(:test)
    did_init = false
    plugin.init { did_init = true }
    Rpush::Daemon.common_init
    expect(did_init).to be_true
  end

  it 'logs an error if the store cannot be loaded' do
    Rpush.config.client = :foo_bar
    Rpush.logger.should_receive(:error).with(kind_of(LoadError))
    Rpush::Daemon.stub(:exit) { Rpush::Daemon.store = double.as_null_object }
    Rpush::Daemon.start
  end

  it "writes the process ID to the PID file" do
    Rpush::Daemon.should_receive(:write_pid_file)
    Rpush::Daemon.start
  end

  it "logs an error if the PID file could not be written" do
    Rpush.config.pid_file = '/rails_root/rpush.pid'
    File.stub(:open).and_raise(Errno::ENOENT)
    logger.should_receive(:error).with(%r{Failed to write PID to '/rails_root/rpush\.pid'})
    Rpush::Daemon.start
  end

  it "starts the feeder" do
    Rpush::Daemon::Feeder.should_receive(:start)
    Rpush::Daemon.start
  end

  it "syncs apps" do
    Rpush::Daemon::Synchronizer.should_receive(:sync)
    Rpush::Daemon.start
  end

  describe "shutdown" do
    it "stops the feeder" do
      Rpush::Daemon::Feeder.should_receive(:stop)
      Rpush::Daemon.shutdown
    end

    it "stops the app runners" do
      Rpush::Daemon::AppRunner.should_receive(:stop)
      Rpush::Daemon.shutdown
    end

    it "removes the PID file if one was written" do
      Rpush.config.pid_file = "/rails_root/rpush.pid"
      File.stub(:exist?).and_return(true)
      File.should_receive(:delete).with("/rails_root/rpush.pid")
      Rpush::Daemon.shutdown
    end

    it "does not attempt to remove the PID file if it does not exist" do
      File.stub(:exists?).and_return(false)
      File.should_not_receive(:delete)
      Rpush::Daemon.shutdown
    end

    it "does not attempt to remove the PID file if one was not written" do
      Rpush.config.pid_file = nil
      File.should_not_receive(:delete)
      Rpush::Daemon.shutdown
    end
  end
end
