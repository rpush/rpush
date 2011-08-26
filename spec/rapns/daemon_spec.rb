require "spec_helper"

describe Rapns::Daemon do
  module Rails
  end

  before do
    Rails.stub(:root).and_return("/rails_root")

    @configuration = Rapns::Daemon::Configuration.new("development", "/rails_root/config/rapns/rapns.yml")
    @configuration.stub(:read_config).and_return({"development" => {"port" => 123, "host" => "localhost", "certificate" => "development.pem", "certificate_password" => "abc123"}})
    Rapns::Daemon::Configuration.stub(:new).and_return(@configuration)

    @certificate = Rapns::Daemon::Certificate.new("/rails_root/config/rapns/development.pem")
    @certificate.stub(:read_certificate).and_return("certificate contents")
    Rapns::Daemon::Certificate.stub(:new).and_return(@certificate)

    @connection = Rapns::Daemon::Connection.new
    @connection.stub(:connect)
    Rapns::Daemon::Connection.stub(:new).and_return(@connection)

    Rapns::Daemon::Runner.stub(:start)
    Rapns::Daemon.stub(:daemonize)
    @logger = mock("Logger")
    Rapns::Daemon::Logger.stub(:new).and_return(@logger)
  end

  it "should load the configuration" do
    Rapns::Daemon::Configuration.should_receive(:new).with("development", "/rails_root/config/rapns/rapns.yml").and_return(@configuration)
    @configuration.load
    @configuration.should_receive(:load)
    Rapns::Daemon.start("development", {})
  end

  it "should make the configuration accessible" do
    Rapns::Daemon.start("development", {})
    Rapns::Daemon.configuration.should == @configuration
  end

  it "should load the certificate" do
    Rapns::Daemon::Certificate.should_receive(:new).with("/rails_root/config/rapns/development.pem").and_return(@certificate)
    @certificate.should_receive(:load)
    Rapns::Daemon.start("development", {})
  end

  it "should make the certificate accessible" do
    Rapns::Daemon.start("development", {})
    Rapns::Daemon.certificate.should == @certificate
  end

  it "should connect to the APNS" do
    Rapns::Daemon::Connection.should_receive(:new).and_return(@connection)
    @connection.should_receive(:connect)
    Rapns::Daemon.start("development", {})
  end

  it "should make the connection accessible" do
    Rapns::Daemon.start("development", {})
    Rapns::Daemon.connection.should == @connection
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
  end

  it "should make the logger accessible" do
    Rapns::Daemon::Logger.stub(:new).with(true).and_return(@logger)
    Rapns::Daemon.start("development", {:poll => 2, :foreground => true})
    Rapns::Daemon.logger.should == @logger
  end
end