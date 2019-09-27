require 'unit_spec_helper'

shared_examples 'Rpush::Client::Notification' do
  let(:notification) { described_class.new }

  it 'allows assignment of many registration IDs' do
    notification.registration_ids = %w[a b]
    expect(notification.registration_ids).to eq %w[a b]
  end

  it 'allows assignment of a single registration ID' do
    notification.registration_ids = 'a'
    expect(notification.registration_ids).to eq ['a']
  end

  it 'saves its parent App if required' do
    notification.app = Rpush::App.new(name: "aname")
    expect(notification.app).to be_valid
    expect(notification).to be_valid
  end
end
