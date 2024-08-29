require 'unit_spec_helper'

shared_examples 'Rpush::Client::Fcm::Notification' do
  let(:app) { Rpush::Fcm::App.create!(name: 'test', auth_key: 'abc') }
  let(:notification) { described_class.new }

  it "has a 'data' payload limit of 4096 bytes" do
    notification.app = app
    notification.device_token = "valid"
    notification.data = { key: "a" * 4096 }
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:base]).to eq ["Notification payload data cannot be larger than 4096 bytes."]
  end

  it "validates notification keys" do
    notification.app = app
    notification.device_token = "valid"
    notification.notification = { "title" => "valid", "body" => "valid", "color" => "valid for android", "garbage" => "invalid" }
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:notification]).to eq ["contains invalid keys: garbage"]
  end

  it "allows notifications with either symbol keys or string keys" do
    notification.app = app
    notification.notification = { "title" => "title", body: "body" }
    expect(notification.as_json['message']['notification']).to eq({"title"=>"title", "body"=>"body"})
  end

  it "moves notification keys to the correcdt location" do
    notification.app = app
    notification.device_token = "valid"
    notification.notification = { "title" => "valid", "body" => "valid", "color" => "valid for android" }
    expect(notification.valid?).to be_truthy
    expect(notification.as_json['message']['notification']).to eq("title"=>"valid", "body"=>"valid")
    expect(notification.as_json['message']['android']['notification']['color']).to eq('valid for android')
  end

  it 'validates expiry is present if collapse_key is set' do
    notification.collapse_key = 'test'
    notification.expiry = nil
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:expiry]).to eq ['must be set when using a collapse_key']
  end

  it 'includes time_to_live in the payload' do
    notification.expiry = 100
    expect(notification.as_json['message']['android']['ttl']).to eq '100s'
  end

  it 'includes content_available in the payload' do
    notification.content_available = true
    expect(notification.as_json["message"]["apns"]["payload"]["aps"]["content-available"]).to eq 1
  end

  it 'sets the priority to high when set to high' do
    notification.notification = { title: "Title" }
    notification.priority = 'high'
    expect(notification.as_json['message']['android']['priority']).to eq 'high'
    expect(notification.as_json['message']['android']['notification']['notification_priority']).to eq 'PRIORITY_MAX'
    # TODO Add notification_priority
  end

  it 'sets the priority to normal when set to normal' do
    notification.notification = { title: "Title" }
    notification.priority = 'normal'
    expect(notification.as_json['message']['android']['priority']).to eq 'normal'
    expect(notification.as_json['message']['android']['notification']['notification_priority']).to eq 'PRIORITY_DEFAULT'
    # TODO Add notification_priority
  end

  it 'validates the priority is either "normal" or "high"' do
    notification.priority = 'invalid'
    expect(notification.errors[:priority]).to eq ['must be one of either "normal" or "high"']
  end

  it 'excludes the priority if it is not defined' do
    expect(notification.as_json['message']['android']).not_to have_key 'priority'
  end

  it 'includes the notification payload if defined' do
    notification.notification = { key: 'any key is allowed' }
    expect(notification.as_json['message']).to have_key 'notification'
  end

  it 'excludes the notification payload if undefined' do
    expect(notification.as_json['message']).not_to have_key 'notification'
  end

  it 'fails when trying to set the dry_run option' do
    expect { notification.dry_run = true }.to raise_error(ArgumentError)
  end
end
