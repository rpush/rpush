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

  it 'limits the number of registration ids to 1000' do
    notification.registration_ids = ['a'] * (1000 + 1)
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:base]).to eq ["Number of registration_ids cannot be larger than 1000."]
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
    expect(notification.as_json['message']['content_available']).to eq true
  end

  it 'fails if mutable_content is provided' do
    expect { notification.mutable_content = true }.to raise_error(ArgumentError)
  end

  it 'sets the priority to high when set to high' do
    notification.priority = 'high'
    expect(notification.as_json['message']['android']['priority']).to eq 'high'
    expect(notification.as_json['message']['android']['notification']['notification_priority']).to eq 'PRIORITY_MAX'
    # TODO Add notification_priority
  end

  it 'sets the priority to normal when set to normal' do
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
