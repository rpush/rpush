require "spec_helper"

describe Rapns::Daemon::DeliveryHandler do
  let(:queue) { Rapns::Daemon::DeliveryQueue.new }
  let(:name) { 'my_app:0' }
  let(:host) { 'localhost' }
  let(:port) { 2195 }
  let(:certificate) { stub }
  let(:password) { stub }
  let(:delivery_handler) { Rapns::Daemon::DeliveryHandler.new(queue, name, host, port, certificate, password) }
  let(:connection) { stub(:select => false, :write => nil, :reconnect => nil, :close => nil) }
  let(:logger) { stub(:error => nil, :info => nil) }
  let(:notification) { stub.as_null_object }
  let(:configuration) { stub(:check_for_errors => true) }
  let(:delivery_queues) { [] }

  before do
    Rapns::Daemon::Connection.stub(:new => connection)
    Rapns::Daemon.stub(:delivery_queues => delivery_queues, :logger => logger, :configuration => configuration)
    queue.push(notification) 
  end

  it "instantiates a new connection" do
    Rapns::Daemon::Connection.should_receive(:new).with("DeliveryHandler:#{name}", host, port, certificate, password)
    delivery_handler
  end

  it "connects the socket when started" do
    connection.should_receive(:connect)
    delivery_handler.start
    delivery_handler.stop
  end

  it "pushes a STOP instruction into the queue when told to stop" do
    queue.should_receive(:push).with(Rapns::Daemon::DeliveryHandler::STOP)
    delivery_handler.stop
  end

  it "sends the binary version of the notification" do
    notification.stub(:to_binary => "hi mom")
    connection.should_receive(:write).with("hi mom")
    delivery_handler.send(:handle_next_notification)
  end

  it "logs the notification delivery" do
    notification.stub(:id => 666, :device_token => 'abc123')
    logger.should_receive(:info).with("[DeliveryHandler:my_app:0] 666 sent to abc123")
    delivery_handler.send(:handle_next_notification)
  end

  it "marks the notification as delivered" do
    notification.should_receive(:delivered=).with(true)
    delivery_handler.send(:handle_next_notification)
  end

  it "sets the time the notification was delivered" do
    now = Time.now
    Time.stub(:now).and_return(now)
    notification.should_receive(:delivered_at=).with(now)
    delivery_handler.send(:handle_next_notification)
  end

  it "does not trigger validations when saving the notification" do
    notification.should_receive(:save!).with(:validate => false)
    delivery_handler.send(:handle_next_notification)
  end

  it "updates notification with the ability to reconnect the database" do
    delivery_handler.should_receive(:with_database_reconnect_and_retry)
    delivery_handler.send(:handle_next_notification)
  end

  it "logs if an error is raised when updating the notification" do
    e = StandardError.new("bork!")
    notification.stub(:save!).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    delivery_handler.send(:handle_next_notification)
  end

  it "notifies the delivery queue the notification has been processed" do
    queue.should_receive(:notification_processed)
    delivery_handler.send(:handle_next_notification)
  end

  it 'does not check for errors if check_for_errors config option is false' do
    configuration.stub(:check_for_errors => false)
    delivery_handler.should_not_receive(:check_for_error)
    delivery_handler.send(:handle_next_notification)
  end

  describe "when being stopped" do
    before { queue.pop }

    it "closes the connection when a STOP instruction is received" do
      connection.should_receive(:close)
      queue.push(Rapns::Daemon::DeliveryHandler::STOP)
      delivery_handler.send(:handle_next_notification)
    end

    it "does not attempt to deliver a notification when a STOP instruction is received" do
      queue.push(Rapns::Daemon::DeliveryHandler::STOP)
      delivery_handler.should_not_receive(:deliver)
      delivery_handler.send(:handle_next_notification)
    end
  end

  describe "when delivery fails" do
    before { connection.stub(:select => true, :read => [8, 4, 69].pack("ccN")) }

    it "updates notification with the ability to reconnect the database" do
      delivery_handler.should_receive(:with_database_reconnect_and_retry)
      delivery_handler.send(:handle_next_notification)
    end

    it "sets the notification as not delivered" do
      notification.should_receive(:delivered=).with(false)
      delivery_handler.send(:handle_next_notification)
    end

    it "sets the notification delivered_at timestamp to nil" do
      notification.should_receive(:delivered_at=).with(nil)
      delivery_handler.send(:handle_next_notification)
    end

    it "sets the notification as failed" do
      notification.should_receive(:failed=).with(true)
      delivery_handler.send(:handle_next_notification)
    end

    it "sets the notification failed_at timestamp" do
      now = Time.now
      Time.stub(:now).and_return(now)
      notification.should_receive(:failed_at=).with(now)
      delivery_handler.send(:handle_next_notification)
    end

    it "sets the notification error code" do
      notification.should_receive(:error_code=).with(4)
      delivery_handler.send(:handle_next_notification)
    end

    it "logs the delivery error" do
      error = Rapns::DeliveryError.new(4, 12, "Missing payload")
      Rapns::DeliveryError.stub(:new => error)
      logger.should_receive(:error).with(error)
      delivery_handler.send(:handle_next_notification)
    end

    it "sets the notification error description" do
      notification.should_receive(:error_description=).with("Missing payload")
      delivery_handler.send(:handle_next_notification)
    end

    it "skips validation when saving the notification" do
      notification.should_receive(:save!).with(:validate => false)
      delivery_handler.send(:handle_next_notification)
    end

    it "reads 6 bytes from the socket" do
      connection.should_receive(:read).with(6).and_return(nil)
      delivery_handler.send(:handle_next_notification)
    end

    it "does not attempt to read from the socket if the socket was not selected for reading after the timeout" do
      connection.stub(:select => nil)
      connection.should_not_receive(:read)
      delivery_handler.send(:handle_next_notification)
    end

    it "reconnects the socket" do
      connection.should_receive(:reconnect)
      delivery_handler.send(:handle_next_notification)
    end

    it "logs that the connection is being reconnected" do
      Rapns::Daemon.logger.should_receive(:error).with("[DeliveryHandler:my_app:0] Error received, reconnecting...")
      delivery_handler.send(:handle_next_notification)
    end

    context "when the APNs disconnects without returning an error" do
      before do
        connection.stub(:read => nil)
      end

      it 'raises a DisconnectError error if the connection is closed without an error being returned' do
        error = Rapns::DisconnectionError.new
        Rapns::DisconnectionError.should_receive(:new).and_return(error)
        Rapns::Daemon.logger.should_receive(:error).with(error)
        delivery_handler.send(:handle_next_notification)
      end

      it 'does not set the error code on the notification' do
        notification.should_receive(:error_code=).with(nil)
        delivery_handler.send(:handle_next_notification)
      end

      it 'sets the error descriptipon on the notification' do
        notification.should_receive(:error_description=).with("APNs disconnected without returning an error.")
        delivery_handler.send(:handle_next_notification)
      end
    end
  end
end