require "spec_helper"

describe Rapns::Daemon, "when starting" do
  module Rails; end

  let(:certificate) { stub }
  let(:password) { stub }
  let(:config) { stub(:pid_file => nil, :push_poll => 2, :airbrake_notify => false, :foreground => true) }
  let(:logger) { stub(:info => nil, :error => nil, :warn => nil) }

  before do
    Rapns::Daemon::Feeder.stub(:start)
    Rapns::Daemon::Logger.stub(:new).and_return(logger)
    Rapns::Daemon::AppRunner.stub(:sync => nil, :stop => nil)
    Rapns::Daemon.stub(:daemonize => nil, :reconnect_database => nil, :exit => nil, :puts => nil)
    File.stub(:open)
    Rails.stub(:root).and_return("/rails_root")
  end

  it "forks into a daemon if the foreground option is false" do
    config.stub(:foreground => false)
    ActiveRecord::Base.stub(:establish_connection)
    Rapns::Daemon.should_receive(:daemonize)
    Rapns::Daemon.start(config)
  end

  it "does not fork into a daemon if the foreground option is true" do
    config.stub(:foreground => true)
    Rapns::Daemon.should_not_receive(:daemonize)
    Rapns::Daemon.start(config)
  end

  it "writes the process ID to the PID file" do
    Rapns::Daemon.should_receive(:write_pid_file)
    Rapns::Daemon.start(config)
  end

  it "logs an error if the PID file could not be written" do
    config.stub(:pid_file => '/rails_root/rapns.pid')
    File.stub(:open).and_raise(Errno::ENOENT)
    logger.should_receive(:error).with("Failed to write PID to '/rails_root/rapns.pid': #<Errno::ENOENT: No such file or directory>")
    Rapns::Daemon.start(config)
  end

  it "starts the feeder" do
    Rapns::Daemon::Feeder.should_receive(:start).with(2)
    Rapns::Daemon.start(config)
  end

  it "syncs apps" do
    Rapns::Daemon::AppRunner.should_receive(:sync)
    Rapns::Daemon.start(config)
  end

  it "sets up the logger" do
    config.stub(:airbrake_notify => true)
    Rapns::Daemon::Logger.should_receive(:new).with(:foreground => true, :airbrake_notify => true)
    Rapns::Daemon.start(config)
  end

  it "makes the logger accessible" do
    Rapns::Daemon.start(config)
    Rapns::Daemon.logger.should == logger
  end

  it 'prints a warning if there are no apps' do
    Rapns::App.stub(:count => 0)
    logger.should_receive(:warn).any_number_of_times
    Rapns::Daemon.start(config)
  end

  it 'prints a warning exists if rapns has not been upgraded' do
    Rapns::App.stub(:count).and_raise(ActiveRecord::StatementInvalid)
    Rapns::Daemon.should_receive(:puts).any_number_of_times
    Rapns::Daemon.should_receive(:exit).with(1)
    Rapns::Daemon.start(config)
  end

  it 'warns if rapns.yml still exists' do
    File.should_receive(:exists?).with('/rails_root/config/rapns/rapns.yml').and_return(true)
    logger.should_receive(:warn).with("Since 2.0.0 rapns uses command-line options instead of a configuration file. Please remove config/rapns/rapns.yml.")
    Rapns::Daemon.start(config)
  end
end

describe Rapns::Daemon, "when being shutdown" do
  let(:config) { stub(:pid_file => '/rails_root/rapns.pid') }

  before do
    Rapns::Daemon.stub(:config => config, :puts => nil)
    Rapns::Daemon::Feeder.stub(:stop)
    Rapns::Daemon::AppRunner.stub(:stop)
  end

  it "stops the feeder" do
    Rapns::Daemon::Feeder.should_receive(:stop)
    Rapns::Daemon.send(:shutdown)
  end

  it "stops the app runners" do
    Rapns::Daemon::AppRunner.should_receive(:stop)
    Rapns::Daemon.send(:shutdown)
  end

  it "removes the PID file if one was written" do
    File.stub(:exists?).and_return(true)
    File.should_receive(:delete).with("/rails_root/rapns.pid")
    Rapns::Daemon.send(:shutdown)
  end

  it "does not attempt to remove the PID file if it does not exist" do
    File.stub(:exists?).and_return(false)
    File.should_not_receive(:delete)
    Rapns::Daemon.send(:shutdown)
  end

  it "does not attempt to remove the PID file if one was not written" do
    config.stub(:pid_file).and_return(nil)
    File.should_not_receive(:delete)
    Rapns::Daemon.send(:shutdown)
  end
end