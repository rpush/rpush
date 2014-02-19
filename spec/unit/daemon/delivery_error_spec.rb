require "unit_spec_helper"

describe Rpush::DeliveryError do
  let(:error) { Rpush::DeliveryError.new(4, 12, "Missing payload") }

  it "returns an informative message" do
    error.to_s.should eq "Unable to deliver notification 12, received error 4 (Missing payload)"
  end

  it "returns the error code" do
    error.code.should eq 4
  end
end
