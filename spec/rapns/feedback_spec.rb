require "spec_helper"

describe Rapns::Feedback do
  it { should validate_presence_of(:device_token) }
  it { should validate_presence_of(:failed_at) }

  it "should validate the format of the device_token" do
    notification = Rapns::Feedback.new(:device_token => "{$%^&*()}")
    notification.valid?.should be_false
    notification.errors[:device_token].include?("is invalid").should be_true
  end
end