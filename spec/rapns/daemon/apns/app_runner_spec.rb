require 'spec_helper'
require File.dirname(__FILE__) + '/../app_runner_shared.rb'

describe Rapns::Daemon::Apns::AppRunner do
  it_behaves_like "an AppRunner subclass"

  let(:push_config) { stub(:host => 'gateway.push.apple.com', :port => 2195) }
  let(:feedback_config) { stub(:host => 'feedback.push.apple.com', :port => 2196, :poll => 60) }
  let(:app) { stub(:app, :key => 'app', :certificate => 'cert', :password => '', :connections => 1) }
  let(:new_app) { stub(:new_app, :key => 'app', :certificate => 'cert', :password => '', :connections => 1) }
  let(:runner) { Rapns::Daemon::Apns::AppRunner.new(app, push_config.host, push_config.port,
    feedback_config.host, feedback_config.port, feedback_config.poll) }
  let(:receiver) { stub(:start => nil, :stop => nil) }
  let(:handler) { stub(:handler, :start => nil, :stop => nil) }

  before do
    Rapns::Daemon::FeedbackReceiver.stub(:new => receiver)
    Rapns::Daemon::DeliveryHandler.stub(:new => handler)
  end

  it 'starts a feedback receiver' do
    Rapns::Daemon::FeedbackReceiver.should_receive(:new).with(app.key, feedback_config.host, feedback_config.port, feedback_config.poll, app.certificate, app.password)
    receiver.should_receive(:start)
    runner.start
  end

  it 'stops the feedback receiver' do
    runner.start
    receiver.should_receive(:stop)
    runner.stop
  end
end