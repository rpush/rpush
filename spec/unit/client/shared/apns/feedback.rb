# frozen_string_literal: true

require 'unit_spec_helper'

shared_examples 'Rpush::Client::Apns::Feedback' do
  it 'validates the format of the device_token' do
    notification = described_class.new(device_token: "{$%^&*()}")
    expect(notification).not_to be_valid
    expect(notification.errors[:device_token]).to include('is invalid')
  end
end
