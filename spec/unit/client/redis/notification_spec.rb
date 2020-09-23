require 'unit_spec_helper'

describe Rpush::Client::Redis::Notification do
  let(:notification) { Rpush::Client::Redis::Notification.new }

  it 'allows assignment of many registration IDs' do
    notification.registration_ids = %w(a b)
    expect(notification.registration_ids).to eq %w(a b)
  end

  it 'allows assignment of a single registration ID' do
    skip "Doesn't work on Redis yet"
    notification.registration_ids = 'a'
    expect(notification.registration_ids).to eq ['a']
  end

  it 'saves its parent App if required' do
    skip "Doesn't work on Redis yet"
    notification.app = Rpush::Client::Redis::App.new(name: "aname")
    expect(notification.app).to be_valid
    expect(notification).to be_valid
  end

  it 'does not mix notification and data payloads' do
    notification.data = { key: 'this is data' }
    notification.notification = { key: 'this is notification' }
    expect(notification.data.stringify_keys).to eq('key' => 'this is data')
    expect(notification.notification.stringify_keys).to eq('key' => 'this is notification')
  end
end if redis?
