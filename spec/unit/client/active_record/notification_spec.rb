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
end
