require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Notification do
  let(:notification) { Rpush::Client::ActiveRecord::Notification.new }

  it 'allows assignment of many registration IDs' do
    notification.registration_ids = %w(a b)
    notification.registration_ids.should eq %w(a b)
  end

  it 'allows assignment of a single registration ID' do
    notification.registration_ids = 'a'
    notification.registration_ids.should eq ['a']
  end

  it 'saves its parent App if required' do
    notification.app = Rpush::Client::ActiveRecord::App.new(name: "aname")
    expect(notification.app).to be_valid
    expect(notification).to be_valid
  end
end
