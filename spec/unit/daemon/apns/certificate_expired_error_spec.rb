require 'spec_helper'

describe Rpush::Apns::CertificateExpiredError do
  let(:app) { double(:name => 'test') }
  let(:error) { Rpush::Apns::CertificateExpiredError.new(app, Time.now) }

  it 'returns a message' do
    error.message
    error.to_s
  end
end
