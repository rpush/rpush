require 'unit_spec_helper'
require 'unit/notification_shared.rb'

describe Rpush::Client::ActiveRecord::Adm::Notification do
  it_should_behave_like 'an Notification subclass'

  let(:app) { Rpush::Client::ActiveRecord::Adm::App.create!(:name => 'test', :client_id => 'CLIENT_ID', :client_secret => 'CLIENT_SECRET') }
  let(:notification_class) { Rpush::Client::ActiveRecord::Adm::Notification }
  let(:notification) { notification_class.new }

  it "has a 'data' payload limit of 6144 bytes" do
    notification.data = { :key => "a" * 6144 }
    notification.valid?.should be_false
    notification.errors[:base].should eq ["Notification payload data cannot be larger than 6144 bytes."]
  end

  it 'limits the number of registration ids to 100' do
    notification.registration_ids = ['a']*(100+1)
    notification.valid?.should be_false
    notification.errors[:base].should eq ["Number of registration_ids cannot be larger than 100."]
  end

  it 'validates data can be blank if collapse_key is set' do
    notification.app = app
    notification.registration_ids = 'a'
    notification.collapse_key = 'test'
    notification.data = nil
    notification.valid?.should be_true
    notification.errors[:data].should be_empty
  end

  it 'validates data is present if collapse_key is not set' do
    notification.collapse_key = nil
    notification.data = nil
    notification.valid?.should be_false
    notification.errors[:data].should eq ['must be set unless collapse_key is specified']
  end

  it 'includes expiresAfter in the payload' do
    notification.expiry = 100
    notification.as_json['expiresAfter'].should eq 100
  end
end
