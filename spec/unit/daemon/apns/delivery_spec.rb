require 'unit_spec_helper'

describe Rapns::Daemon::Apns::Delivery do
  let(:app) { stub(:name => 'MyApp') }
  let(:notification) { stub.as_null_object }
  let(:logger) { stub(:error => nil, :info => nil) }
  let(:config) { stub(:check_for_errors => true) }
  let(:connection) { stub(:select => false, :write => nil, :reconnect => nil, :close => nil, :connect => nil) }
  let(:delivery) { Rapns::Daemon::Apns::Delivery.new(app, connection, notification) }

  def perform
    begin
      delivery.perform
    rescue Rapns::DeliveryError, Rapns::Apns::DisconnectionError
    end
  end

  before do
    Rapns::Daemon.stub(:logger => logger, :config => config)
  end

  it "sends the binary version of the notification" do
    notification.stub(:to_binary => "hi mom")
    connection.should_receive(:write).with("hi mom")
    perform
  end

  it "logs the notification delivery" do
    notification.stub(:id => 666, :device_token => 'abc123')
    logger.should_receive(:info).with("[MyApp] 666 sent to abc123")
    perform
  end

  it "marks the notification as delivered" do
    notification.should_receive(:delivered=).with(true)
    perform
  end

  it "sets the time the notification was delivered" do
    now = Time.now
    Time.stub(:now).and_return(now)
    notification.should_receive(:delivered_at=).with(now)
    perform
  end

  it "does not trigger validations when saving the notification" do
    notification.should_receive(:save!).with(:validate => false)
    perform
  end

  it "updates notification with the ability to reconnect the database" do
    delivery.should_receive(:with_database_reconnect_and_retry)
    perform
  end

  it 'does not check for errors if check_for_errors config option is false' do
    config.stub(:check_for_errors => false)
    delivery.should_not_receive(:check_for_error)
    perform
  end

  describe "when delivery fails" do
    before { connection.stub(:select => true, :read => [8, 4, 69].pack("ccN")) }

    it "updates notification with the ability to reconnect the database" do
      delivery.should_receive(:with_database_reconnect_and_retry)
      perform
    end

    it "sets the notification as not delivered" do
      notification.should_receive(:delivered=).with(false)
      perform
    end

    it "sets the notification delivered_at timestamp to nil" do
      notification.should_receive(:delivered_at=).with(nil)
      perform
    end

    it "sets the notification as failed" do
      notification.should_receive(:failed=).with(true)
      perform
    end

    it "sets the notification failed_at timestamp" do
      now = Time.now
      Time.stub(:now).and_return(now)
      notification.should_receive(:failed_at=).with(now)
      perform
    end

    it "sets the notification error code" do
      notification.should_receive(:error_code=).with(4)
      perform
    end

    it "logs the delivery error" do
      # checking for the stubbed error doesn't work in jruby, but checking
      # for the exception by class does.

      #error = Rapns::DeliveryError.new(4, 12, "Missing payload")
      #Rapns::DeliveryError.stub(:new => error)
      #expect { delivery.perform }.to raise_error(error)

      expect { delivery.perform }.to raise_error(Rapns::DeliveryError)
    end

    it "sets the notification error description" do
      notification.should_receive(:error_description=).with("Missing payload")
      perform
    end

    it "skips validation when saving the notification" do
      notification.should_receive(:save!).with(:validate => false)
      perform
    end

    it "reads 6 bytes from the socket" do
      connection.should_receive(:read).with(6).and_return(nil)
      perform
    end

    it "does not attempt to read from the socket if the socket was not selected for reading after the timeout" do
      connection.stub(:select => nil)
      connection.should_not_receive(:read)
      perform
    end

    it "reconnects the socket" do
      connection.should_receive(:reconnect)
      perform
    end

    it "logs that the connection is being reconnected" do
      Rapns::Daemon.logger.should_receive(:error).with("[MyApp] Error received, reconnecting...")
      perform
    end

    context "when the APNs disconnects without returning an error" do
      before do
        connection.stub(:read => nil)
      end

      it 'raises a DisconnectError error if the connection is closed without an error being returned' do
        expect { delivery.perform }.to raise_error(Rapns::Apns::DisconnectionError)
      end

      it 'does not set the error code on the notification' do
        notification.should_receive(:error_code=).with(nil)
        perform
      end

      it 'sets the error description on the notification' do
        notification.should_receive(:error_description=).with("APNs disconnected without returning an error.")
        perform
      end
    end
  end
end
