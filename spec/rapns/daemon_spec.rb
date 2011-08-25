require "spec_helper"

describe Rapns::Daemon do
  module Rails
    def self.logger
      @logger
    end

    def self.logger=(logger)
      @logger = logger
    end
  end

  before do
    Rapns::Daemon::Configuration.stub(:load)
    Rapns::Daemon::Configuration.stub(:certificate)
    Rapns::Daemon::Certificate.stub(:load)
    Rapns::Daemon::Connection.stub(:connect)
    Rapns::Daemon::Runner.stub(:start)
    Rapns::Daemon.stub(:fork)
    Rails.stub(:root).and_return("/rails_root")
    logger = mock("BufferedLogger", :info => nil, :error => nil, :level => 0, :auto_flushing => 1, :auto_flushing= => nil)
    Rails.logger = logger
    ActiveSupport::BufferedLogger.stub(:new).and_return(logger)
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
    Rapns::Daemon.should_receive(:fork)
    Rapns::Daemon.start("development", {:foreground => false})
  end

  it "should not fork a child process if the foreground option is true" do
    Rapns::Daemon.should_not_receive(:fork)
    Rapns::Daemon.start("development", {:foreground => true})
  end

  it "should start the runner, passing the poll frequency as an argument" do
    Rapns::Daemon::Runner.should_receive(:start).with(2)
    Rapns::Daemon.start("development", {:poll => 2})
  end
end