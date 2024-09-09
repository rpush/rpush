# frozen_string_literal: true

require 'unit_spec_helper'

describe Rpush::CertificateExpiredError do
  let(:app) { double(name: 'test') }
  let(:error) { described_class.new(app, Time.zone.now) }

  it 'returns a message' do
    error.message
    error.to_s
  end
end
