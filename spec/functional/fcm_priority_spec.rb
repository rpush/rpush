require 'functional_spec_helper'

describe 'FCM priority' do
  let(:app) { Rpush::Fcm::App.new }
  let(:notification) { Rpush::Fcm::Notification.new }
  let(:hydrated_notification) { Rpush::Fcm::Notification.find(notification.id) }
  let(:response) { double(Net::HTTPResponse, code: 200) }
  let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }
  let(:priority) { 'normal' }
  let(:fake_device_token) { 'a' * 108 }

  before do
    app.name = 'test'
    app.auth_key = 'abc123'
    app.save!

    notification.app_id = app.id
    notification.device_token = fake_device_token
    notification.data = { message: 'test' }
    notification.notification = { title: 'title' }
    notification.priority = priority
    notification.save!

    allow(Net::HTTP::Persistent).to receive_messages(new: http)
  end

  it 'supports normal priority' do
    json = hydrated_notification.as_json
    expect(json["message"]["android"]["notification"]["notification_priority"]).to eq('PRIORITY_DEFAULT')
    expect(json["message"]["android"]["priority"]).to eq('normal')
  end

  context 'high priority' do
    let(:priority) { 'high' }

    it 'supports high priority' do
      json = hydrated_notification.as_json
      expect(json["message"]["android"]["notification"]["notification_priority"]).to eq('PRIORITY_MAX')
      expect(json["message"]["android"]["priority"]).to eq('high')
    end
  end

  it 'does not add an error when receiving expected priority' do
    expect(hydrated_notification.errors.messages[:priority]).to be_empty
  end
end
