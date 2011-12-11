require "spec_helper"

describe Rapns::Daemon::DeliveryHandler do
  let(:delivery_handler) { Rapns::Daemon::DeliveryHandler.new(0) }

  before do
    @notification = Rapns::Notification.create!(:device_token => "a" * 64)
    Rapns::Daemon.stub(:delivery_queue).and_return(Rapns::Daemon::DeliveryQueue.new)
    Rapns::Daemon.delivery_queue.push(@notification)
    @connection = mock("Connection", :connect => nil, :write => nil, :close => nil, :select => nil, :read => nil)
    Rapns::Daemon::Connection.stub(:new).and_return(@connection)
    configuration = mock("Configuration", :push => stub(:host => "gateway.push.apple.com", :port => 2195))
    Rapns::Daemon.stub(:configuration).and_return(configuration)
    @logger = mock("Logger", :error => nil, :info => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
  end

  it "instantiates a new connection" do
    Rapns::Daemon::Connection.should_receive(:new).with('DeliveryHandler 0', 'gateway.push.apple.com', 2195)
    delivery_handler
  end

  it "connects the socket when started" do
    @connection.should_receive(:connect)
    delivery_handler.start
    delivery_handler.stop
  end

  it "pushes a STOP instruction into the queue when told to stop" do
    Rapns::Daemon.delivery_queue.should_receive(:push).with(Rapns::Daemon::DeliveryHandler::STOP)
    delivery_handler.stop
  end

  it "closes the connection when a STOP instruction is received" do
    Rapns::Daemon.delivery_queue.push(Rapns::Daemon::DeliveryHandler::STOP)
    delivery_handler.send(:handle_next_notification)
  end

  it "should pop a new notification from the delivery queue" do
    Rapns::Daemon.delivery_queue.should_receive(:pop)
    delivery_handler.send(:handle_next_notification)
  end

  it "does not attempt to deliver a notification when a STOP instruction is received" do
    Rapns::Daemon.delivery_queue.pop # empty the queue
    delivery_handler.should_not_receive(:deliver)
    Rapns::Daemon.delivery_queue.push(Rapns::Daemon::DeliveryHandler::STOP)
    delivery_handler.send(:handle_next_notification)
  end

  it "should send the binary version of the notification" do
    @notification.stub((:to_binary)).and_return("hi mom")
    @connection.should_receive(:write).with("hi mom")
    delivery_handler.send(:handle_next_notification)
  end

  it "should log the notification delivery" do
    Rapns::Daemon.logger.should_receive(:info).with("Notification #{@notification.id} delivered to #{@notification.device_token}")
    delivery_handler.send(:handle_next_notification)
  end

  it "should mark the notification as delivered" do
    expect { delivery_handler.send(:handle_next_notification); @notification.reload }.to change(@notification, :delivered).to(true)
  end

  it "should set the time the notification was delivered" do
    @notification.delivered_at.should be_nil
    delivery_handler.send(:handle_next_notification)
    @notification.reload
    @notification.delivered_at.should be_kind_of(Time)
  end

  it "should not trigger validations when saving the notification" do
    @notification.should_receive(:save!).with(:validate => false)
    delivery_handler.send(:handle_next_notification)
  end

  it "should log if an error is raised when updating the notification" do
    e = StandardError.new("bork!")
    @notification.stub(:save!).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    delivery_handler.send(:handle_next_notification)
  end

  it "should notify the delivery queue the notification has been processed" do
    Rapns::Daemon.delivery_queue.should_receive(:notification_processed)
    delivery_handler.send(:handle_next_notification)
  end

  describe "when delivery fails" do
    before do
      @connection.stub(:select => true, :read => [8, 4, 69].pack("ccN"), :reconnect => nil)
    end

    it "should set the notification as not delivered" do
      @notification.should_receive(:delivered=).with(false)
      delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification delivered_at timestamp to nil" do
      @notification.should_receive(:delivered_at=).with(nil)
      delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification as failed" do
      @notification.should_receive(:failed=).with(true)
      delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification failed_at timestamp" do
      now = Time.now
      Time.stub(:now).and_return(now)
      @notification.should_receive(:failed_at=).with(now)
      delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification error code" do
      @notification.should_receive(:error_code=).with(4)
      delivery_handler.send(:handle_next_notification)
    end

    it "should log the delivery error" do
      error = Rapns::DeliveryError.new(4, "Missing payload", 69)
      Rapns::DeliveryError.stub(:new => error)
      Rapns::Daemon.logger.should_receive(:error).with(error)
      delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification error description" do
      @notification.should_receive(:error_description=).with("Missing payload")
      delivery_handler.send(:handle_next_notification)
    end

    it "should skip validation when saving the notification" do
      @notification.should_receive(:save!).with(:validate => false)
      delivery_handler.send(:handle_next_notification)
    end

    it "should read 6 bytes from the socket" do
      @connection.should_receive(:read).with(6).and_return(nil)
      delivery_handler.send(:handle_next_notification)
    end

    it "should not attempt to read from the socket if the socket was not selected for reading after the timeout" do
      @connection.stub(:select => nil)
      @connection.should_not_receive(:read)
      delivery_handler.send(:handle_next_notification)
    end

    it 'should raise an error if the connection is closed without an error being returned' do
      @connection.stub(:read => nil)
      description = "The APNs disconnected without returning an error. This may indicate you are using an invalid certificate for the host."
      error = Rapns::DeliveryError.new(nil, description, nil)
      Rapns::DeliveryError.should_receive(:new).with(nil, description, nil).and_return(error)
      Rapns::Daemon.logger.should_receive(:error).with(error)
      delivery_handler.send(:handle_next_notification)
    end

    it "should reconnect the socket" do
      @connection.should_receive(:reconnect)
      delivery_handler.send(:handle_next_notification)
    end

    it "should log that the connection is being reconnected" do
      Rapns::Daemon.logger.should_receive(:error).with("[DeliveryHandler 0] Error received, reconnecting...")
      delivery_handler.send(:handle_next_notification)
    end
  end
end