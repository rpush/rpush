require 'functional_spec_helper'

describe 'Retries' do
  let(:app) { Rpush::Fcm::App.new }
  let(:notification) { Rpush::Fcm::Notification.new }
  let(:response) { double(Net::HTTPResponse, code: 200) }
  let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }

  before do
    Rpush::Daemon.common_init

    app.name = 'test'
    app.auth_key = 'abc123'
    app.save!

    notification.app_id = app.id
    notification.device_token = 'foo'
    notification.data = { message: 'test' }
    notification.save!

    Modis.with_connection do |redis|
      redis.del(Rpush::Client::Redis::Notification.absolute_pending_namespace)
    end

    allow(Net::HTTP::Persistent).to receive_messages(new: http)
    allow(response).to receive_messages(body: JSON.dump(results: [{ message_id: notification.device_token }]))
  end

  it 'delivers a notification due to be retried' do
    Rpush::Daemon.store.mark_retryable(notification, Time.now - 1.minute)
    Rpush.push
    notification.reload
    expect(notification.delivered).to eq(true)
  end

  it 'does not deliver a notification not due to be retried' do
    Rpush::Daemon.store.mark_retryable(notification, Time.now + 1.minute)
    Rpush.push
    notification.reload
    expect(notification.delivered).to eq(false)
  end
end if redis?
