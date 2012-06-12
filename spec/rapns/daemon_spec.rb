require "spec_helper"

describe Rapns::Daemon, "when starting" do
  module Rails; end

  let(:certificate) { stub }
  let(:password) { stub }
  let(:my_app_config) { stub(:connections => 3, :certificate => certificate, :certificate_password => password) }
  let(:feedback_config) { stub(:host => 'feedback.push.apple.com', :port => 2196, :poll => 60) }
  let(:push_config) { stub(:poll => 2, :host => 'gateway.push.apple.com', :port => 2195) }
  let(:configuration) { stub(:pid_file => nil, :push => push_config, :airbrake_notify => false,
    :feedback => feedback_config, :apps => { 'my_app' => my_app_config }) }
  let(:handler_pool) { stub(:<< => nil) }
  let(:queue) { stub }
  let(:delivery_handler) { stub }
  let(:receiver) { stub }
  let(:receiver_pool) { stub(:<< => nil) }
  let(:logger) { stub(:info => nil, :error => nil) }

  before do
    Rapns::Daemon::Configuration.stub(:load).and_return(configuration)
    Rapns::Daemon::DeliveryHandlerPool.stub(:new).and_return(handler_pool)
    Rapns::Daemon::FeedbackReceiverPool.stub(:new).and_return(receiver_pool)
    Rapns::Daemon::DeliveryQueue.stub(:new).and_return(queue)
    Rapns::Daemon::FeedbackReceiver.stub(:new => receiver)
    Rapns::Daemon::DeliveryHandler.stub(:new => delivery_handler)
    Rapns::Daemon::Feeder.stub(:start)
    Rapns::Daemon::Logger.stub(:new).and_return(logger)
    Rapns::Daemon.stub(:daemonize, :reconnect_database)
    File.stub(:open)
    Rails.stub(:root).and_return("/rails_root")
  end

  it "loads the configuration" do
    Rapns::Daemon::Configuration.should_receive(:load).with("development", "/rails_root/config/rapns/rapns.yml")
    Rapns::Daemon.start("development", {})
  end

  it "makes the configuration accessible" do
    Rapns::Daemon.start("development", true)
    Rapns::Daemon.configuration.should == configuration
  end

  it "makes the delivery handler pool accessible" do
    Rapns::Daemon.start("development", {})
    Rapns::Daemon.handler_pool.should == handler_pool
  end

  it "makes the feedback receiver pool accessible" do
    Rapns::Daemon.start("development", {})
    Rapns::Daemon.receiver_pool.should == receiver_pool
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

  it "sets up the logger" do
    configuration.stub(:airbrake_notify => true)
    Rapns::Daemon::Logger.should_receive(:new).with(:foreground => true, :airbrake_notify => true)
    Rapns::Daemon.start("development", true)
  end

  it "makes the logger accessible" do
    Rapns::Daemon.start("development", true)
    Rapns::Daemon.logger.should == logger
  end

  it 'instantiates delivery handlers' do
    Rapns::Daemon::DeliveryHandler.should_receive(:new).with(queue, "my_app:0", configuration.push.host,
      configuration.push.port, my_app_config.certificate, my_app_config.certificate_password)
    Rapns::Daemon.start("development", true)
  end

  it 'starts a delivery handler for each connection' do
    Rapns::Daemon::DeliveryHandler.should_receive(:new).exactly(3).times
    Rapns::Daemon.start("development", true)
  end

  it 'adds the delivery handler to the pool' do
    handler_pool.should_receive(:<<).with(delivery_handler)
    Rapns::Daemon.start("development", true)
  end

  it 'starts a feedback receiver for each app' do
    Rapns::Daemon::FeedbackReceiver.should_receive(:new).with('my_app', configuration.feedback.host, configuration.feedback.port,
      configuration.feedback.poll, my_app_config.certificate, my_app_config.certificate_password)
    Rapns::Daemon.start("development", true)
  end

  it 'adds the feedback receiver to the pool' do
    receiver_pool.should_receive(:<<).with(receiver)
    Rapns::Daemon.start("development", true)
  end
end

describe Rapns::Daemon, "when being shutdown" do
  let(:configuration) { stub(:pid_file => '/rails_root/rapns.pid') }
  let(:handler_pool) { stub(:drain => nil) }
  let(:receiver_pool) { stub(:drain => nil) }

  before do
    Rails.stub(:root).and_return("/rails_root")
    Rapns::Daemon::Feeder.stub(:stop)
    Rapns::Daemon::FeedbackReceiver.stub(:stop)
    Rapns::Daemon.stub(:handler_pool).and_return(handler_pool)
    Rapns::Daemon.stub(:receiver_pool).and_return(receiver_pool)
    Rapns::Daemon.stub(:configuration).and_return(configuration)
    Rapns::Daemon.stub(:puts)
  end

  it "stops the feeder" do
    Rapns::Daemon::Feeder.should_receive(:stop)
    Rapns::Daemon.send(:shutdown)
  end

  it "drains the delivery handler pool" do
    handler_pool.should_receive(:drain)
    Rapns::Daemon.send(:shutdown)
  end

  it "does not attempt to drain the delivery handler pool if it has not been initialized" do
    Rapns::Daemon.stub(:handler_pool).and_return(nil)
    handler_pool.should_not_receive(:drain)
    Rapns::Daemon.send(:shutdown)
  end

  it "drains the feedback receiver pool" do
    receiver_pool.should_receive(:drain)
    Rapns::Daemon.send(:shutdown)
  end

  it "does not attempt to drain the delivery handler pool if it has not been initialized" do
    Rapns::Daemon.stub(:receiver_pool).and_return(nil)
    receiver_pool.should_not_receive(:drain)
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