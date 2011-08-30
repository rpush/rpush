require "spec_helper"

describe Rapns::DeliveryError do
  before do
    @error = Rapns::DeliveryError.new(4, "Missing payload", 12)
  end

  it "should give an informative message" do
    @error.message.should == "Unable to deliver notification 12, received APN error 4 (Missing payload)"
  end
end