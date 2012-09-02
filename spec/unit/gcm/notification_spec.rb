require 'unit_spec_helper'
require 'unit/notification_shared.rb'

describe Rapns::Gcm::Notification do
  it_should_behave_like 'an Notification subclass'

  let(:notification_class) { Rapns::Gcm::Notification }
  let(:notification) { notification_class.new }
  let(:data_setter) { 'data=' }
  let(:data_getter) { 'data' }

  it { should validate_presence_of :registration_ids }

  it 'has a payload limit of 4096 bytes'
  it 'allows assignment of many registration IDs'
  it 'allows assignment of a single registration ID'
end