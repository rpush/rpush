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
      @error = Rapns::DeliveryError.new(4, "Missing payload", 69)
      Rapns::DeliveryError.stub(:new => @error)
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
      Rapns::Daemon.logger.should_receive(:error).with(@error)
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

    it "should not raise a DeliveryError if the packet cmd value is not 8" do
      @connection.stub(:read).and_return([6, 4, 12].pack("ccN"))
      expect { delivery_handler.send(:handle_next_notification) }.should_not raise_error(Rapns::DeliveryError)
    end

    it "should not raise a DeliveryError if the status code is 0 (no error)" do
      @connection.stub(:read).and_return([8, 0, 12].pack("ccN"))
      expect { delivery_handler.send(:handle_next_notification) }.should_not raise_error(Rapns::DeliveryError)
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

    it "should not raise a DeliveryError if the socket read returns nothing" do
      @connection.stub(:read).with(6).and_return(nil)
      expect { delivery_handler.send(:handle_next_notification) }.should_not raise_error(Rapns::DeliveryError)
    end

    it "should reconnect the socket" do
      @connection.should_receive(:reconnect)
      begin
        delivery_handler.send(:handle_next_notification)
      rescue Rapns::DeliveryError
      end
    end

    it "should log that the connection is being reconnected" do
      Rapns::Daemon.logger.should_receive(:error).with("[DeliveryHandler 0] Error received, reconnecting...")
      begin
        delivery_handler.send(:handle_next_notification)
      rescue Rapns::DeliveryError
      end
    end
  end
end

# describe Rapns::Daemon::Connection, "when receiving an error packet" do
#   before do
#     @notification = Rapns::Notification.create!(:device_token => "a" * 64)
#     @notification.stub(:save!)
#     @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
#     @ssl_socket = mock("SSLSocket", :write => nil, :flush => nil, :close => nil, :read => [8, 4, @notification.id].pack("ccN"))
#     @connection.stub(:setup_ssl_context)
#     @connection.stub(:connect_socket).and_return([@tcp_socket, @ssl_socket])
#     IO.stub(:select).and_return([@ssl_socket, [], []])
#     logger = mock("Logger", :error => nil, :warn => nil)
#     Rapns::Daemon.stub(:logger).and_return(logger)
#     @connection.connect
#   end
# 
#   it "should raise a DeliveryError when an error is received" do
#     expect { @connection.write("msg with an error") }.should raise_error(Rapns::DeliveryError)
#   end
# 

# end