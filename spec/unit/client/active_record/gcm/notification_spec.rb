require 'unit_spec_helper'
require 'unit/notification_shared.rb'

describe Rpush::Client::ActiveRecord::Gcm::Notification do
  it_should_behave_like 'an Notification subclass'

  let(:app) { Rpush::Client::ActiveRecord::Gcm::App.create!(name: 'test', auth_key: 'abc') }
  let(:notification_class) { Rpush::Client::ActiveRecord::Gcm::Notification }
  let(:notification) { notification_class.new }

  it "has a 'data' payload limit of 4096 bytes" do
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
    expect(notification.as_json['time_to_live']).to eq 100
  end
end if active_record?
