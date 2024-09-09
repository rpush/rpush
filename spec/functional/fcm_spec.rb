require 'functional_spec_helper'

describe 'FCM' do
  let(:app) { Rpush::Fcm::App.new }
  let(:notification) { Rpush::Fcm::Notification.new }
  let(:response) { double(Net::HTTPResponse, code: 200) }
  let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }
  let(:fake_device_token) { 'a' * 108 }
  let(:creds) {double(Google::Auth::UserRefreshCredentials)}

  before do
    app.name = 'test'
    app.auth_key = 'abc123'
    app.save!

    notification.app_id = app.id
    notification.device_token = fake_device_token
    notification.data = { message: 'test' }
    notification.save!

    allow(Net::HTTP::Persistent).to receive_messages(new: http)
    allow(creds).to receive(:fetch_access_token).and_return({'access_token': 'face_access_token'})

    allow(::Google::Auth::ServiceAccountCredentials).to receive(:fetch_access_token).and_return({access_token: 'bbbbbb'})
    allow(::Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(creds)
    allow_any_instance_of(::Rpush::Daemon::Fcm::Delivery).to receive(:necessary_data_exists?).and_return(true)
  end

  it 'delivers a notification successfully' do
    example_success_body = {
      "multicast_id": 108,
      "success": 1,
      "failure": 0,
      "canonical_ids": 0,
      "results": [
        { "message_id": "1:08" }
      ]
    }.to_json
    allow(response).to receive_messages(body: example_success_body)

    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end

  it 'fails to deliver a notification successfully' do
    example_error_body = {
      "error": {
        "code": 400,
        "message": "The registration token is not a valid FCM registration token",
        "errors": [
          {
            "message": "The registration token is not a valid FCM registration token",
            "domain": "global",
            "reason": "badRequest"
          }
        ],
        "status": "INVALID_ARGUMENT"
      }
    }.to_json

    allow(response).to receive_messages(code: 400, body: example_error_body)
    Rpush.push
    notification.reload
    expect(notification.delivered).to eq(false)
  end

  it 'retries notification that fail due to a SocketError' do
    expect(http).to receive(:request).and_raise(SocketError.new)
    expect(notification.deliver_after).to be_nil
    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :deliver_after).to(kind_of(Time))
  end
end
