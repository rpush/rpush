require 'functional_spec_helper'

  describe 'HMS' do
    let(:app) { Fixtures.build(:hms_app) }
    let(:notification_with_data) { Rpush::Hms::Notification.new }
    let(:response) { double(Net::HTTPResponse, code: 200, body: { code: '80000000' }.to_json) }
    let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }

    before do
      allow_any_instance_of(Rpush::Daemon::Hms::Token).to receive(:token).and_return('token')

      app.name = 'test'
      app.hms_app_id = 'hms-app-id'
      app.auth_key = 'auth-key'
      app.save!

      notification_with_data.app = app
      notification_with_data.title = 'title'
      notification_with_data.body = 'body'
      notification_with_data.set_uri(app.hms_app_id)
      notification_with_data.click_action = {
        type: Rpush::Hms::Notification::CLICK_CUSTOM
      }.stringify_keys

      notification_with_data.save!
      allow(Net::HTTP::Persistent).to receive_messages(new: http)
    end

    it 'delivers a notification successfully' do
      expect do
        Rpush.push
        notification_with_data.reload
      end.to change(notification_with_data, :delivered).to(true)
    end

    it 'fails to deliver a notification with data successfully' do
      allow(response).to receive_messages(code: 400)

      expect do
        Rpush.push
        notification_with_data.reload
      end.to change(notification_with_data, :failed_at)
    end

    it 'retries notification that fail due to a SocketError' do
      expect(http).to receive(:request).and_raise(SocketError.new).once
      expect(notification_with_data.deliver_after).to be_nil
      expect do
        Rpush.push
        notification_with_data.reload
      end.to change(notification_with_data, :deliver_after).to(kind_of(Time))
    end
  end
