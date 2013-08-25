require 'unit_spec_helper'

describe Rapns::Daemon::Apns::Delivery do
  let(:app) { double(:name => 'MyApp') }
  let(:notification) { double.as_null_object }
  let(:batch) { double(:mark_failed => nil, :mark_delivered => nil) }
  let(:logger) { double(:error => nil, :info => nil) }
  let(:config) { double(:check_for_errors => true) }
  let(:connection) { double(:select => false, :write => nil, :reconnect => nil, :close => nil, :connect => nil) }
  let(:delivery) { Rapns::Daemon::Apns::Delivery.new(app, connection, notification, batch) }

  def perform
    begin
      delivery.perform
    rescue Rapns::DeliveryError, Rapns::Apns::DisconnectionError
    end
  end

  before do
    Rapns.stub(:config => config, :logger => logger)
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
    batch.should_receive(:mark_delivered).with(notification)
    perform
  end

  it 'reflects the notification was delivered' do
    delivery.should_receive(:reflect).with(:notification_delivered, notification)
    perform
  end

  it 'does not check for errors if check_for_errors config option is false' do
    config.stub(:check_for_errors => false)
    delivery.should_not_receive(:check_for_error)
    perform
  end

  describe "when delivery fails" do
    before { connection.stub(:select => true, :read => [8, 4, 69].pack("ccN")) }

    it "marks the notification as failed" do
      batch.should_receive(:mark_failed).with(notification, 4, "Missing payload")
      perform
    end

    it 'reflects the notification delivery failed' do
      delivery.should_receive(:reflect).with(:notification_failed, notification)
      perform
    end

    it "logs the delivery error" do
      # checking for the doublebed error doesn't work in jruby, but checking
      # for the exception by class does.

      #error = Rapns::DeliveryError.new(4, 12, "Missing payload")
      #Rapns::DeliveryError.stub(:new => error)
      #expect { delivery.perform }.to raise_error(error)

      expect { delivery.perform }.to raise_error(Rapns::DeliveryError)
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
      Rapns.logger.should_receive(:error).with("[MyApp] Error received, reconnecting...")
      perform
    end

    context "when the APNs disconnects without returning an error" do
      before do
        connection.stub(:read => nil)
      end

      it 'raises a DisconnectError error if the connection is closed without an error being returned' do
        expect { delivery.perform }.to raise_error(Rapns::Apns::DisconnectionError)
      end

      it 'marks the notification as failed' do
        batch.should_receive(:mark_failed).with(notification, nil, "APNs disconnected without returning an error.")
        perform
      end
    end
  end
end
