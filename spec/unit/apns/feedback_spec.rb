require "unit_spec_helper"

describe Rpush::Apns::Feedback do
  it "should validate the format of the device_token" do
    notification = Rpush::Apns::Feedback.new(:device_token => "{$%^&*()}")
    notification.valid?.should be_false
    notification.errors[:device_token].include?("is invalid").should be_true
  end
end
