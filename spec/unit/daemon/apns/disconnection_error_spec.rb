require 'unit_spec_helper'

describe Rapns::Apns::DisconnectionError do
  let(:error) { Rapns::Apns::DisconnectionError.new }

  it 'returns a nil error code' do
    error.code.should be_nil
  end

  it 'contains an error description' do
    error.description
  end

  it 'returns a message' do
    error.message
    error.to_s
  end
end
