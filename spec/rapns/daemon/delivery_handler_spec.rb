require "spec_helper"

describe Rapns::Daemon::DeliveryHandler do
  before do
    @notification = Rapns::Notification.create!(:device_token => "a" * 64)
    Rapns::Daemon.stub(:delivery_queue).and_return(Rapns::Daemon::DeliveryQueue.new(1))
    Rapns::Daemon.delivery_queue.push(@notification)
    @connection = mock("Connection", :connect => nil, :write => nil)
    Rapns::Daemon::Connection.stub(:new).and_return(@connection)
    @connection_pool = Rapns::Daemon::ConnectionPool.new(1)
    @connection_pool.populate
    Rapns::Daemon.stub(:connection_pool).and_return(@connection_pool)
    @delivery_handler = Rapns::Daemon::DeliveryHandler.new
    @logger = mock("Logger", :error => nil, :info => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
  end

  it "should pop a new notification from the delivery queue" do
    Rapns::Daemon.delivery_queue.should_receive(:pop)
    @delivery_handler.send(:handle_next_notification)
  end

  it "should claim a connection for the delivery" do
    Rapns::Daemon.connection_pool.should_receive(:claim_connection)
    @delivery_handler.send(:handle_next_notification)
  end

  it "should send the binary version of the notification" do
    @notification.stub((:to_binary)).and_return("hi mom")
    @connection.should_receive(:write).with("hi mom")
    @delivery_handler.send(:handle_next_notification)
  end

  it "should log the notification delivery" do
    Rapns::Daemon.logger.should_receive(:info).with("Notification #{@notification.id} delivered to #{@notification.device_token}")
    @delivery_handler.send(:handle_next_notification)
  end

  it "should mark the notification as delivered" do
    expect { @delivery_handler.send(:handle_next_notification); @notification.reload }.to change(@notification, :delivered).to(true)
  end

  it "should set the time the notification was delivered" do
    @notification.delivered_at.should be_nil
    @delivery_handler.send(:handle_next_notification)
    @notification.reload
    @notification.delivered_at.should be_kind_of(Time)
  end

  it "should not trigger validations when saving the notification" do
    @notification.should_receive(:save!).with(:validate => false)
    @delivery_handler.send(:handle_next_notification)
  end

  it "should log if an error is raised when updating the notification" do
    e = StandardError.new("bork!")
    @notification.stub(:save!).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    @delivery_handler.send(:handle_next_notification)
  end

  it "should notify the delivery queue a handler is now available" do
    Rapns::Daemon.delivery_queue.should_receive(:handler_available)
    @delivery_handler.send(:handle_next_notification)
  end

  describe "when delivery fails" do
    before do
      @error = Rapns::DeliveryError.new(4, "Missing payload", 1)
      @connection.stub(:write).and_raise(@error)
    end

    it "should set the notification as not delivered" do
      @notification.should_receive(:delivered=).with(false)
      @delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification delivered_at timestamp to nil" do
      @notification.should_receive(:delivered_at=).with(nil)
      @delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification as failed" do
      @notification.should_receive(:failed=).with(true)
      @delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification failed_at timestamp" do
      now = Time.now
      Time.stub(:now).and_return(now)
      @notification.should_receive(:failed_at=).with(now)
      @delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification error code" do
      @notification.should_receive(:error_code=).with(4)
      @delivery_handler.send(:handle_next_notification)
    end

    it "should log the delivery error" do
      Rapns::Daemon.logger.should_receive(:error).with(@error)
      @delivery_handler.send(:handle_next_notification)
    end

    it "should set the notification error description" do
      @notification.should_receive(:error_description=).with("Missing payload")
      @delivery_handler.send(:handle_next_notification)
    end

    it "should skip validation when saving the notification" do
      @notification.should_receive(:save!).with(:validate => false)
      @delivery_handler.send(:handle_next_notification)
    end
  end
end