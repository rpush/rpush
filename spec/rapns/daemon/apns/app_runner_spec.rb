require "spec_helper"

describe Rapns::Daemon::Apns::AppRunner do

let(:push_config) { stub(:host => 'gateway.push.apple.com', :port => 2195) }
  let(:feedback_config) { stub(:host => 'feedback.push.apple.com', :port => 2196, :poll => 60) }
let(:runner) { Rapns::Daemon::AppRunner.new(app, push_config.host, push_config.port,
    feedback_config.host, feedback_config.port, feedback_config.poll) }

  it 'starts a feedback receiver' do
    Rapns::Daemon::FeedbackReceiver.should_receive(:new).with(app.key, feedback_config.host, feedback_config.port, feedback_config.poll, app.certificate, app.password)
    receiver.should_receive(:start)
    runner.start
  end

  it 'stops the feedback receiver' do
      receiver.should_receive(:stop)
      runner.stop
    end
end