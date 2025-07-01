require 'unit_spec_helper'

describe Rpush::Daemon::Dispatcher::Apnsp8Http2 do
  let(:app) { double(environment: "sandbox", apn_key: "my_key") }
  let(:delivery_class) { double }
  let(:notification) { double }
  let(:batch) { double(mark_delivered: nil, all_processed: nil) }
  let(:http2) { double(on: true) }
  let!(:token_provider) { double }
  let(:queue_payload) { Rpush::Daemon::QueuePayload.new(batch, notification) }
  let(:dispatcher) { described_class.new(app, delivery_class) }

  it 'constructs a new persistent connection' do
    expect(NetHttp2::Client).to receive(:new).and_call_original
    described_class.new(app, delivery_class)
  end

  describe 'dispatch' do
    before do
      allow(NetHttp2::Client).to receive_messages(new: http2)
      allow(Rpush::Daemon::Apnsp8::Token).to receive_messages(new: token_provider)
    end

    it 'delivers the notification' do
      delivery = double
      expect(delivery_class).to receive(:new).with(app, http2, token_provider, batch).and_return(delivery)
      expect(delivery).to receive(:perform)
      dispatcher.dispatch(queue_payload)
    end
  end

  describe 'error catching' do
    let(:dispatcher) { described_class.new(app, Rpush::Daemon::Apnsp8::Delivery) }
    let(:client) { dispatcher.instance_variable_get("@client") }
    let(:notification1) { double('Notification 1', data: {}, as_json: {}).as_null_object }

    before do
      allow(batch).to receive(:each_notification) do |&blk|
        [notification1].each(&blk)
      end
      allow_any_instance_of(Rpush::Daemon::Apnsp8::Delivery).to receive(:prepare_headers).and_return({})
      allow(client).to receive(:socket_loop).and_raise(Errno::ECONNRESET)
    end

    it 'records and raises errors' do
      expect(batch).to receive(:mark_all_retryable)
      expect(client).to receive(:record_error).with(Errno::ECONNRESET).and_call_original
      payload = Rpush::Daemon::QueuePayload.new(batch, notification)
      expect do
        dispatcher.dispatch(payload)
      end.to raise_error(Errno::ECONNRESET)
    end
  end
end
