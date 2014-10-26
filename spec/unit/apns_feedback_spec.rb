require 'unit_spec_helper'

describe Rpush, 'apns_feedback' do
  let!(:app) { Rpush::Apns::App.create!(name: 'test', environment: 'production', certificate: TEST_CERT) }
  let(:receiver) { double(check_for_feedback: nil) }

  before do
    Rpush::Daemon::Apns::FeedbackReceiver.stub(new: receiver)
  end

  it 'initializes the daemon' do
    Rpush::Daemon.should_receive(:common_init)
    Rpush.apns_feedback
  end

  it 'checks feedback for each app' do
    Rpush::Daemon::Apns::FeedbackReceiver.should_receive(:new).with(app).and_return(receiver)
    receiver.should_receive(:check_for_feedback)
    Rpush.apns_feedback
  end
end
