require 'unit_spec_helper'
require File.dirname(__FILE__) + '/../app_runner_shared.rb'

describe Rapns::Daemon::Apns::AppRunner do
  it_behaves_like 'an AppRunner subclass'

  let(:app_class) { Rapns::Apns::App }
  let(:app) { app_class.create!(:name => 'my_app', :environment => 'development',
                                :certificate => TEST_CERT, :password => 'pass') }
  let(:runner) { Rapns::Daemon::Apns::AppRunner.new(app) }
  let(:handler) { stub(:start => nil, :stop => nil, :queue= => nil) }
  let(:receiver) { stub(:start => nil, :stop => nil) }
  let(:config) { {:feedback_poll => 60 } }
  let(:logger) { stub(:info => nil) }

  before do
    Rapns::Daemon.stub(:logger => logger)
    Rapns::Daemon::Apns::DeliveryHandler.stub(:new => handler)
    Rapns::Daemon::Apns::FeedbackReceiver.stub(:new => receiver)
    Rapns::Daemon.stub(:config => config)
  end

  it 'instantiates a new feedback receiver when started' do
    Rapns::Daemon::Apns::FeedbackReceiver.should_receive(:new).with(app, 'feedback.sandbox.push.apple.com',
                                                                    2196, 60)
    runner.start
  end

  it 'starts the feedback receiver' do
    receiver.should_receive(:start)
    runner.start
  end

  it 'stops the feedback receiver' do
    runner.start
    receiver.should_receive(:stop)
    runner.stop
  end
end
