require "spec_helper"

describe Rapns::Daemon, "when starting" do
  module Rails
  end

  before do
    Rails.stub(:root).and_return("/rails_root")

    @configuration = Rapns::Daemon::Configuration.new("development", "/rails_root/config/rapns/rapns.yml")
    @configuration.stub(:read_config).and_return({"development" => {"port" => 123, "host" => "localhost", "certificate" => "development.pem", "certificate_password" => "abc123", "pid_file" => "rapns.pid"}})
    Rapns::Daemon::Configuration.stub(:new).and_return(@configuration)

    @certificate = Rapns::Daemon::Certificate.new("/rails_root/config/rapns/development.pem")
    @certificate.stub(:read_certificate).and_return("certificate contents")
    Rapns::Daemon::Certificate.stub(:new).and_return(@certificate)

    @connection_pool = Rapns::Daemon::ConnectionPool.new(3)
    @connection_pool.stub(:populate)
    Rapns::Daemon::ConnectionPool.stub(:new).and_return(@connection_pool)

    @handler_pool = Rapns::Daemon::DeliveryHandlerPool.new(3)
    @handler_pool.stub(:populate)
    Rapns::Daemon::DeliveryHandlerPool.stub(:new).and_return(@handler_pool)

    Rapns::Daemon::Feeder.stub(:start)
    Rapns::Daemon::Feeder.stub(:wait)
    Rapns::Daemon.stub(:daemonize)
    Rapns::Daemon.stub(:write_pid_file)
    @logger = mock("Logger", :info => nil)
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

  it "should populate the connection pool" do
    Rapns::Daemon::ConnectionPool.should_receive(:new).with(3).and_return(@connection_pool)
    @connection_pool.should_receive(:populate)
    Rapns::Daemon.start("development", {})
  end

  it "should initialize the delivery queue with the number of connection as its signal point" do
    Rapns::Daemon::DeliveryQueue.should_receive(:new).with(3)
    Rapns::Daemon.start("development", {})
  end

  it "should make the connection pool accessible" do
    Rapns::Daemon.start("development", {})
    Rapns::Daemon.connection_pool.should == @connection_pool
  end

  it "should populate the delivery handler pool" do
    Rapns::Daemon::DeliveryHandlerPool.should_receive(:new).with(3).and_return(@handler_pool)
    @handler_pool.should_receive(:populate)
    Rapns::Daemon.start("development", {})
  end

  it "should make the delivery handler pool accessible" do
    Rapns::Daemon.start("development", {})
    Rapns::Daemon.delivery_handler_pool.should == @handler_pool
  end

  it "should fork a child process if the foreground option is false" do
    ActiveRecord::Base.stub(:establish_connection)
    Rapns::Daemon.should_receive(:daemonize)
    Rapns::Daemon.start("development", false)
  end

  it "should re-establish the connection to the database after being forked" do
    ActiveRecord::Base.should_receive(:establish_connection)
    Rapns::Daemon.stub(:daemonize)
    Rapns::Daemon.start("development", false)
  end

  it "should not fork a child process if the foreground option is true" do
    Rapns::Daemon.should_not_receive(:daemonize)
    Rapns::Daemon.start("development", true)
  end

  it "should write the process ID to the PID file" do
    Rapns::Daemon.should_receive(:write_pid_file)
    Rapns::Daemon.start("development", {})
  end

  it "should start the feeder" do
    Rapns::Daemon::Feeder.should_receive(:start)
    Rapns::Daemon.start("development", true)
  end

  it "should setup the logger" do
    Rapns::Daemon::Logger.should_receive(:new).with(:foreground => true, :airbrake_notify => true).and_return(@logger)
    Rapns::Daemon.start("development", true)
  end

  it "should make the logger accessible" do
    Rapns::Daemon::Logger.stub(:new).and_return(@logger)
    Rapns::Daemon.start("development", true)
    Rapns::Daemon.logger.should == @logger
  end
end

describe Rapns::Daemon, "when being shutdown" do
  before do
    Rails.stub(:root).and_return("/rails_root")
    Rapns::Daemon::Feeder.stub(:stop)
    @connection_pool = mock("ConnectionPool", :drain => nil)
    Rapns::Daemon.stub(:connection_pool).and_return(@connection_pool)
    @handler_pool = mock("DeliveryHandlerPool", :drain => nil)
    Rapns::Daemon.stub(:delivery_handler_pool).and_return(@handler_pool)
    @configuration = mock("Configuration", :pid_file => File.join(Rails.root, "rapns.pid"))
    Rapns::Daemon.stub(:configuration).and_return(@configuration)
    Rapns::Daemon.stub(:puts)
  end

  it "should stop the feeder" do
    Rapns::Daemon::Feeder.should_receive(:stop)
    Rapns::Daemon.send(:shutdown)
  end

  it "should drain the connection pool" do
    @connection_pool.should_receive(:drain)
    Rapns::Daemon.send(:shutdown)
  end

  it "should not attempt to drain the connection pool if it has not been initialized" do
    Rapns::Daemon.stub(:connection_pool).and_return(nil)
    @connection_pool.should_not_receive(:drain)
    Rapns::Daemon.send(:shutdown)
  end

  it "should drain the delivery handler pool" do
    @handler_pool.should_receive(:drain)
    Rapns::Daemon.send(:shutdown)
  end

  it "should not attempt to drain the delivery handler pool if it has not been initialized" do
    Rapns::Daemon.stub(:delivery_handler_pool).and_return(nil)
    @handler_pool.should_not_receive(:drain)
    Rapns::Daemon.send(:shutdown)
  end

  it "should remove the PID file if one was written" do
    File.stub(:exists?).and_return(true)
    File.should_receive(:delete).with("/rails_root/rapns.pid")
    Rapns::Daemon.send(:shutdown)
  end

  it "should not attempt to remove the PID file if it does not exist" do
    File.stub(:exists?).and_return(false)
    File.should_not_receive(:delete)
    Rapns::Daemon.send(:shutdown)
  end

  it "should not remove the PID file if one was not written" do
    @configuration.stub(:pid_file).and_return(nil)
    File.should_not_receive(:delete)
    Rapns::Daemon.send(:shutdown)
  end
end