require 'unit_spec_helper'

describe Rapns, 'apns_feedback' do
  let!(:app) { Rapns::Apns::App.create!(:name => 'test', :environment => 'production', :certificate => TEST_CERT) }
  let(:receiver) { double(:check_for_feedback => nil) }

  before do
    Rapns::Daemon::Apns::FeedbackReceiver.stub(:new => receiver)
  end

  it 'initializes the store' do
    Rapns::Daemon.should_receive(:initialize_store)
    Rapns.apns_feedback
  end

  it 'checks feedback for each app' do
    Rapns::Daemon::Apns::FeedbackReceiver.should_receive(:new).with(app, 0).and_return(receiver)
    receiver.should_receive(:check_for_feedback)
    Rapns.apns_feedback
  end
end
