require 'spec_helper'

describe Rpush::TooManyRequestsError do
  let(:response) { double(:code => 429, :header => { 'retry-after' => 3600 }) }
  let(:error) { Rpush::TooManyRequestsError.new(429, 12, "Too Many Requests", response) }

  it "returns an informative message" do
    error.to_s.should eq "Too many requests for 12, received error 429 (Too Many Requests) - retry after 3600"
  end

  it "returns the error code" do
    error.code.should eq 429
  end
end
