require "spec_helper"

describe Rapns::Feedback do
  it { should validate_presence_of(:device_token) }
  it { should validate_presence_of(:failed_at) }

  it "should validate the format of the device_token" do
    feedback = Rapns::Feedback.new(:device_token => "{$%^&*()}")
    feedback.valid?.should be_false
    feedback.errors[:device_token].include?("is invalid").should be_true
  end
end