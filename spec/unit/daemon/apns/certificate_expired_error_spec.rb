require 'unit_spec_helper'

describe Rapns::Apns::CertificateExpiredError do
  let(:app) { double(:name => 'test') }
  let(:error) { Rapns::Apns::CertificateExpiredError.new(app, Time.now) }

  it 'returns a message' do
    error.message
    error.to_s
  end
end
