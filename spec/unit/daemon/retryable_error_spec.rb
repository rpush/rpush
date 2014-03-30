require "unit_spec_helper"

describe Rpush::RetryableError do
  let(:response) { double(code: 401, header: { 'retry-after' => 3600 }) }
  let(:error) { Rpush::RetryableError.new(401, 12, "Unauthorized", response) }

  it "returns an informative message" do
    error.to_s.should eq "Retryable error for 12, received error 401 (Unauthorized) - retry after 3600"
  end

  it "returns the error code" do
    error.code.should eq 401
  end
end
