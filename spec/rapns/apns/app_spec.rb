require "spec_helper"

describe Rapns::Apns::App, 'new_runner' do
  let(:app) { Rapns::Apns::App.new }
  let(:runner) { stub }
  let(:config) { stub(:feedback_poll => 60) }

  before { Rapns::Daemon.stub(:config => config) }

  it 'creates a runner with a production certificate' do
    app.environment = 'production'
    Rapns::App.stub(:all => [app])
    Rapns::Daemon::AppRunner.should_receive(:new).with(app, 'gateway.push.apple.com', 2195,
      'feedback.push.apple.com', 2196, config.feedback_poll).and_return(runner)
    app.new_runner.should == runner
  end

  it 'creates a runner with a development certificate' do
    app.environment = 'development'
    Rapns::App.stub(:all => [app])
    Rapns::Daemon::AppRunner.should_receive(:new).with(app, 'gateway.sandbox.push.apple.com', 2195,
      'feedback.sandbox.push.apple.com', 2196, config.feedback_poll).and_return(runner)
    app.new_runner.should == runner
  end
end