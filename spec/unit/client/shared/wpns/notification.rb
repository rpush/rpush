require 'unit_spec_helper'
require 'unit/notification_shared.rb'

shared_examples 'Rpush::Client::Wpns::Notification' do
  it_should_behave_like 'an Notification subclass'
  let(:app) { Rpush::Wpns::App.create!(name: 'test', auth_key: 'abc') }
  let(:notification) { described_class.new }

  it "should have an url in the uri parameter" do
    notification = described_class.new(uri: "somthing")
    notification.valid?
    expect(notification.errors[:uri]).to include('is invalid')
  end

  it "should be invalid if there's no data" do
    notification = described_class.new(data: {})
    notification.valid?
    expect(notification.errors[:data]).to include("can't be blank")
  end
end
