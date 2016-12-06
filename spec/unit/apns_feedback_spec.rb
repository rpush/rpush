require 'unit_spec_helper'

describe Rpush, 'apns_feedback' do
  let!(:apns_app) do
    Rpush::Apns::App.create!(name: 'test', environment: 'production', certificate: TEST_CERT)
  end

  let!(:gcm_app) do
    Rpush::Gcm::App.create!(name: 'MyApp', auth_key: 'abc123')
  end

  let(:receiver) { double(check_for_feedback: nil) }

  before do
    allow(Rpush::Daemon::Apns::FeedbackReceiver).to receive(:new) { receiver }
  end

  it 'initializes the daemon' do
    expect(Rpush::Daemon).to receive(:common_init)
    Rpush.apns_feedback
  end

  it 'checks feedback for each app' do
    expect(Rpush::Daemon::Apns::FeedbackReceiver).to receive(:new).with(apns_app).and_return(receiver)
    expect(receiver).to receive(:check_for_feedback)
    Rpush.apns_feedback
  end
end
