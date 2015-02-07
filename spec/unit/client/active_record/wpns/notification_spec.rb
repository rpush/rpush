require 'unit_spec_helper'
require 'unit/notification_shared.rb'

describe Rpush::Client::ActiveRecord::Wpns::Notification do
  it_should_behave_like 'an Notification subclass'
  let(:app) { Rpush::Client::ActiveRecord::Wpns::App.create!(name: 'test', auth_key: 'abc') }
  let(:notification_class) { Rpush::Client::ActiveRecord::Wpns::Notification }
  let(:notification) { notification_class.new }

  it "should have an url in the uri parameter" do
    notification = Rpush::Client::ActiveRecord::Wpns::Notification.new(uri: "somthing")
    notification.valid?
    expect(notification.errors[:uri]).to include('is invalid')
  end

  it "should be invalid if there's no data" do
    notification = Rpush::Client::ActiveRecord::Wpns::Notification.new(data: {})
    notification.valid?
    expect(notification.errors[:data]).to include("can't be blank")
  end
end if active_record?
