require 'unit_spec_helper'
require 'unit/notification_shared.rb'

describe Rpush::Client::ActiveRecord::Gcm::Notification do
  it_should_behave_like 'an Notification subclass'

  let(:app) { Rpush::Client::ActiveRecord::Gcm::App.create!(name: 'test', auth_key: 'abc') }
  let(:notification_class) { Rpush::Client::ActiveRecord::Gcm::Notification }
  let(:notification) { notification_class.new }

  it "has a 'data' payload limit of 4096 bytes" do
    notification.data = { key: "a" * 4096 }
    notification.valid?.should be_false
    notification.errors[:base].should eq ["Notification payload data cannot be larger than 4096 bytes."]
  end

  it 'limits the number of registration ids to 1000' do
    notification.registration_ids = ['a']*(1000+1)
    notification.valid?.should be_false
    notification.errors[:base].should eq ["Number of registration_ids cannot be larger than 1000."]
  end

  it 'validates expiry is present if collapse_key is set' do
    notification.collapse_key = 'test'
    notification.expiry = nil
    notification.valid?.should be_false
    notification.errors[:expiry].should eq ['must be set when using a collapse_key']
  end

  it 'includes time_to_live in the payload' do
    notification.expiry = 100
    notification.as_json['time_to_live'].should eq 100
  end
end
