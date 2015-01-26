require 'unit_spec_helper'

describe Rpush, 'apns_feedback' do
  let!(:app) { Rpush::Apns::App.create!(name: 'test', environment: 'production', certificate: TEST_CERT) }
  let(:receiver) { double(check_for_feedback: nil) }

  before do
    allow(Rpush::Daemon::Apns::FeedbackReceiver).to receive(:new) { receiver }
  end

  it 'initializes the daemon' do
    expect(Rpush::Daemon).to receive(:common_init)
    Rpush.apns_feedback
  end

  it 'checks feedback for each app' do
    expect(Rpush::Daemon::Apns::FeedbackReceiver).to receive(:new).with(app).and_return(receiver)
    expect(receiver).to receive(:check_for_feedback)
    Rpush.apns_feedback
  end
end
