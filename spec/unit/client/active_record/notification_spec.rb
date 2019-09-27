require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Notification do
  it_behaves_like 'Rpush::Client::Notification'

  subject(:notification) { described_class.new }

  it 'saves its parent App if required' do
    notification.app = Rpush::App.new(name: "aname")
    expect(notification.app).to be_valid
    expect(notification).to be_valid
  end
end if active_record?
