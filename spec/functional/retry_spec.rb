require 'functional_spec_helper'

if redis?
  describe 'Retries' do
    let(:app) { Rpush::Fcm::App.new }
    let(:notification) { Rpush::Fcm::Notification.new }
    let(:response) { double(Net::HTTPResponse, code: 200) }
    let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }
    let(:fake_device_token) { 'a' * 108 }
    let(:creds) { double(Google::Auth::UserRefreshCredentials) }

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
      allow(creds).to receive(:fetch_access_token).and_return({ access_token: 'face_access_token' })

      allow(Google::Auth::ServiceAccountCredentials).to receive(:fetch_access_token).and_return({ access_token: 'bbbbbb' })
      allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(creds)
      allow_any_instance_of(Rpush::Daemon::Fcm::Delivery).to receive(:necessary_data_exists?).and_return(true)

      example_success_body = {
        multicast_id: 108,
        success: 1,
        failure: 0,
        canonical_ids: 0,
        results: [
          { message_id: "1:08" }
        ]
      }.to_json
      allow(response).to receive_messages(body: example_success_body)
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
  end
end
