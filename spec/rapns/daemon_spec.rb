require "spec_helper"

describe Rapns::Daemon, "when starting" do
  module Rails; end

  let(:certificate) { stub }
  let(:password) { stub }
  let(:feedback_config) { stub(:host => 'feedback.push.apple.com', :port => 2196, :poll => 60) }
  let(:push_config) { stub(:poll => 2, :host => 'gateway.push.apple.com', :port => 2195) }
  let(:configuration) { stub(:pid_file => nil, :push => push_config, :airbrake_notify => false,
    :feedback => feedback_config) }
  let(:logger) { stub(:info => nil, :error => nil) }

  before do
    Rapns::Daemon::Configuration.stub(:load).and_return(configuration)
    Rapns::Daemon::Feeder.stub(:start)
    Rapns::Daemon::Logger.stub(:new).and_return(logger)
    Rapns::Daemon::AppRunner.stub(:sync => nil, :stop => nil)
    Rapns::Daemon.stub(:daemonize => nil, :reconnect_database => nil, :exit => nil, :puts => nil)
    File.stub(:open)
    Rails.stub(:root).and_return("/rails_root")
  end

  it "loads the configuration" do
    Rapns::Daemon::Configuration.should_receive(:load).with("development", "/rails_root/config/rapns/rapns.yml")
    Rapns::Daemon.start("development", {})
  end
  
  it "forks into a daemon if the foreground option is false" do
    ActiveRecord::Base.stub(:establish_connection)
    Rapns::Daemon.should_receive(:daemonize)
    Rapns::Daemon.start("development", false)
  end

  it "does not fork into a daemon if the foreground option is true" do
    Rapns::Daemon.should_not_receive(:daemonize)
    Rapns::Daemon.start("development", true)
  end

  it "writes the process ID to the PID file" do
    Rapns::Daemon.should_receive(:write_pid_file)
    Rapns::Daemon.start("development", {})
  end

  it "logs an error if the PID file could not be written" do
    configuration.stub(:pid_file => '/rails_root/rapns.pid')
    File.stub(:open).and_raise(Errno::ENOENT)
    logger.should_receive(:error).with("Failed to write PID to '/rails_root/rapns.pid': #<Errno::ENOENT: No such file or directory>")
    Rapns::Daemon.start("development", {})
  end

  it "starts the feeder" do
    Rapns::Daemon::Feeder.should_receive(:start).with(2)
    Rapns::Daemon.start("development", true)
  end

  it "syncs apps" do
    Rapns::Daemon::AppRunner.should_receive(:sync).with('development')
    Rapns::Daemon.start("development", true)
  end

  it "sets up the logger" do
    configuration.stub(:airbrake_notify => true)
    Rapns::Daemon::Logger.should_receive(:new).with(:foreground => true, :airbrake_notify => true)
    Rapns::Daemon.start("development", true)
  end

  it "makes the logger accessible" do
    Rapns::Daemon.start("development", true)
    Rapns::Daemon.logger.should == logger
  end

  it 'prints a warning exists if there are no apps for the environment' do
    Rapns::App.stub(:count => 0)
    Rapns::Daemon.should_receive(:puts).any_number_of_times
    Rapns::Daemon.should_receive(:exit).with(1)
    Rapns::Daemon.start("development", true)
  end

  it 'prints a warning exists if rapns has not been upgraded' do
    Rapns::App.stub(:count).and_raise(ActiveRecord::StatementInvalid)
    Rapns::Daemon.should_receive(:puts).any_number_of_times
    Rapns::Daemon.should_receive(:exit).with(1)
    Rapns::Daemon.start("development", true)
  end
end

describe Rapns::Daemon, "when being shutdown" do
  let(:configuration) { stub(:pid_file => '/rails_root/rapns.pid') }

  before do
    Rapns::Daemon.stub(:configuration => configuration, :puts => nil)
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
    configuration.stub(:pid_file).and_return(nil)
    File.should_not_receive(:delete)
    Rapns::Daemon.send(:shutdown)
  end
end