require 'unit_spec_helper'

describe Rpush::Daemon::Dispatcher::HmsHttp do
  let(:app) { double }
  let(:delivery_class) { double }
  let(:notification) { double }
  let(:batch) { double }
  let(:http) { double }
  let(:token_provider) { double(new: nil) }
  let(:queue_payload) { Rpush::Daemon::QueuePayload.new(batch, notification) }
  let(:dispatcher) { Rpush::Daemon::Dispatcher::HmsHttp.new(app, delivery_class, token_provider: token_provider) }

  before { allow(Net::HTTP::Persistent).to receive_messages(new: http) }

  it 'constructs a new persistent connection' do
    expect(Net::HTTP::Persistent).to receive(:new)
    Rpush::Daemon::Dispatcher::HmsHttp.new(app, delivery_class, token_provider: token_provider)
  end

  describe 'dispatch' do
    it 'delivers the notification' do
      delivery = double
      expect(delivery_class).to receive(:new).with(app, http, notification, batch, token_provider: nil).and_return(delivery)
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
end
