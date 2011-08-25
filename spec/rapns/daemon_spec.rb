require "spec_helper"

describe Rapns::Daemon do
  before do
    Rapns::Daemon::Configuration.stub(:load)
    Rapns::Daemon::Configuration.stub(:certificate)
    Rapns::Daemon::Certificate.stub(:load)
    Rapns::Daemon::Connection.stub(:connect)
    Rapns::Daemon::Runner.stub(:start)
    Rapns::Daemon.stub(:daemonize)
    Rails.stub(:root).and_return("/rails_root")
    @logger = mock("Logger")
    Rapns::Daemon::Logger.stub(:new).and_return(@logger)
  end

  it "should load the configuration" do
    Rapns::Daemon::Configuration.should_receive(:load).with("development", "/rails_root/config/rapns/rapns.yml")
    Rapns::Daemon.start("development", {})
  end

  it "should load the certificate" do
    Rapns::Daemon::Configuration.stub(:certificate).and_return("/rails_root/config/rapns/development.pem")
    Rapns::Daemon::Certificate.should_receive(:load).with("/rails_root/config/rapns/development.pem")
    Rapns::Daemon.start("development", {})
  end

  it "should connect to the APNS" do
    Rapns::Daemon::Connection.should_receive(:connect)
    Rapns::Daemon.start("development", {})
  end

  it "should fork a child process if the foreground option is false" do
    Rapns::Daemon.should_receive(:daemonize)
    Rapns::Daemon.start("development", {:foreground => false})
  end

  it "should not fork a child process if the foreground option is true" do
    Rapns::Daemon.should_not_receive(:daemonize)
    Rapns::Daemon.start("development", {:foreground => true})
  end

  it "should start the runner, passing the poll frequency as an argument" do
    Rapns::Daemon::Runner.should_receive(:start).with({:poll => 2})
    Rapns::Daemon.start("development", {:poll => 2})
  end

  it "should setup the logger" do
    Rapns::Daemon::Logger.should_receive(:new).with(true).and_return(@logger)
    Rapns::Daemon.start("development", {:poll => 2, :foreground => true})
    Rapns.logger.should == @logger
  end
end