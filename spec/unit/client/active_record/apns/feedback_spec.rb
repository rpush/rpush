require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Apns::Feedback do
  it 'validates the format of the device_token' do
    notification = Rpush::Client::ActiveRecord::Apns::Feedback.new(:device_token => "{$%^&*()}")
    notification.valid?.should be_false
    notification.errors[:device_token].include?("is invalid").should be_true
  end
end
