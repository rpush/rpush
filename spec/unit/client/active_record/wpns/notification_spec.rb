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
    notification.errors[:uri].include?("is invalid").should be_true
  end

  it "should be invalid if there's no data" do
    notification = Rpush::Client::ActiveRecord::Wpns::Notification.new(data: {})
    notification.valid?
    notification.errors[:data].include?("can't be blank").should be_true
  end

  it "should be invalid if there's no alert" do
    notification = Rpush::Client::ActiveRecord::Wpns::Notification.new(alert: nil)
    notification.valid?
    notification.errors[:data].include?("can't be blank").should be_true
  end
end
