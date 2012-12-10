require "unit_spec_helper"

describe Rapns::DeliveryError do
  let(:error) { Rapns::DeliveryError.new(4, 12, "Missing payload") }

  it "returns an informative message" do
    error.to_s.should == "Unable to deliver notification 12, received error 4 (Missing payload)"
  end

  it "returns the error code" do
    error.code.should == 4
  end
end
