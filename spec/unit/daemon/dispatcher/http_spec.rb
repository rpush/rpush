require 'unit_spec_helper'

describe Rpush::Daemon::Dispatcher::Http do
  let(:app) { double }
  let(:delivery_class) { double }
  let(:notification) { double }
  let(:batch) { double }
  let(:http) { double }
  let(:queue_payload) { Rpush::Daemon::QueuePayload.new(batch, notification) }
  let(:dispatcher) { Rpush::Daemon::Dispatcher::Http.new(app, delivery_class) }

  before { allow(Net::HTTP::Persistent).to receive_messages(new: http) }

  it 'constructs a new persistent connection' do
    expect(Net::HTTP::Persistent).to receive(:new)
    Rpush::Daemon::Dispatcher::Http.new(app, delivery_class)
  end

  describe 'dispatch' do
    it 'delivers the notification' do
      delivery = double
      expect(delivery_class).to receive(:new).with(app, http, notification, batch).and_return(delivery)
      expect(delivery).to receive(:perform)
      dispatcher.dispatch(queue_payload)
    end
  end

  describe 'cleanup' do
    it 'closes the connection' do
      expect(http).to receive(:shutdown)
      dispatcher.cleanup
    end
  end

  describe 'proxy configuration' do
    it 'sets the proxy if present' do
      proxy_uri = 'http://proxy.example.com'
      allow(Rpush.config).to receive(:proxy_uri).and_return(proxy_uri)
      expect(http).to receive(:proxy=).with(proxy_uri)
      Rpush::Daemon::Dispatcher::Http.new(app, delivery_class)
    end

    it 'does not set the proxy if not present' do
      allow(Rpush.config).to receive(:proxy_uri).and_return(nil)
      expect(http).not_to receive(:proxy=)
      Rpush::Daemon::Dispatcher::Http.new(app, delivery_class)
    end
  end
end
