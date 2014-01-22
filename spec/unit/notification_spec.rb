require "unit_spec_helper"

describe Rapns::Notification do
  let(:notification) { Rapns::Notification.new }

  it 'allows assignment of many registration IDs' do
    notification.registration_ids = ['a', 'b']
    notification.registration_ids.should eq ['a', 'b']
  end

  it 'allows assignment of a single registration ID' do
    notification.registration_ids = 'a'
    notification.registration_ids.should eq ['a']
  end
end
