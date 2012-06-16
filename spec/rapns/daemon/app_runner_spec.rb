require 'spec_helper'

describe Rapns::Daemon::AppRunner do
  let(:app) { stub(:key => 'app', :certificate => 'cert', :password => '', :connections => 1) }
  let(:queue) { stub(:notifications_processed? => true, :push => nil) }
  let(:receiver) { stub(:start => nil, :stop => nil) }
  let(:handler) { stub(:start => nil, :stop => nil) }
  let(:push_config) { stub(:host => 'gateway.push.apple.com', :port => 2195) }
  let(:feedback_config) { stub(:host => 'feedback.push.apple.com', :port => 2196, :poll => 60) }
  let(:runner) { Rapns::Daemon::AppRunner.new(app, push_config.host, push_config.port,
    feedback_config.host, feedback_config.port, feedback_config.poll) }

  before do
    Rapns::Daemon::DeliveryQueue.stub(:new => queue)
    Rapns::Daemon::FeedbackReceiver.stub(:new => receiver)
    Rapns::Daemon::DeliveryHandler.stub(:new => handler)
  end

  after { Rapns::Daemon::AppRunner.all.clear }

  describe 'start' do
    it 'starts a feedback receiver' do
      Rapns::Daemon::FeedbackReceiver.should_receive(:new).with(app.key, feedback_config.host, feedback_config.port, feedback_config.poll, app.certificate, app.password)
      receiver.should_receive(:start)
      runner.start
    end

    it 'starts a delivery handler for each connection' do
      Rapns::Daemon::DeliveryHandler.should_receive(:new).with(queue, app.key, push_config.host,
        push_config.port, app.certificate, app.password)
      handler.should_receive(:start)
      runner.start
    end
  end

  describe 'deliver' do
    let(:notification) { stub }

    it 'enqueues the notification' do
      queue.should_receive(:push).with(notification)
      runner.deliver(notification)
    end
  end

  describe 'stop' do
    before { runner.start }

    it 'stops the delivery handlers' do
      handler.should_receive(:stop)
      runner.stop
    end

    it 'stops the feedback receiver' do
      receiver.should_receive(:stop)
      runner.stop
    end
  end

  describe 'ready?' do
    it 'is ready if all notifications have been processed' do
      queue.stub(:notifications_processed? => true)
      runner.ready?.should be_true
    end

    it 'is not ready if not all notifications have been processed' do
      queue.stub(:notifications_processed? => false)
      runner.ready?.should be_false
    end
  end

  describe 'sync' do
    let(:new_app) { stub(:key => 'app', :certificate => 'cert', :password => '', :connections => 1) }
    before { runner.start }

    it 'reduces the number of handlers if needed' do
      handler.should_receive(:stop)
      new_app.stub(:connections => app.connections - 1)
      runner.sync(new_app)
    end

    it 'increases the number of handlers if needed' do
      new_handler = stub
      Rapns::Daemon::DeliveryHandler.should_receive(:new).and_return(new_handler)
      new_handler.should_receive(:start)
      new_app.stub(:connections => app.connections + 1)
      runner.sync(new_app)
    end
  end
end

describe Rapns::Daemon::AppRunner, 'stop' do
  let(:runner) { stub }
  before { Rapns::Daemon::AppRunner.all['app'] = runner }
  after { Rapns::Daemon::AppRunner.all.clear }

  it 'stops all runners' do
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.stop
  end
end

describe Rapns::Daemon::AppRunner, 'deliver' do
  let(:runner) { stub }
  let(:notification) { stub(:app => 'app') }
  let(:logger) { stub(:error => nil) }

  before do
    Rapns::Daemon.stub(:logger => logger)
    Rapns::Daemon::AppRunner.all['app'] = runner
  end

  after { Rapns::Daemon::AppRunner.all.clear }

  it 'delivers the notification' do
    runner.should_receive(:deliver).with(notification)
    Rapns::Daemon::AppRunner.deliver(notification)
  end

  it 'logs an error if there is no runner to deliver the notification' do
    notification.stub(:app => 'unknonw', :id => 123)
    logger.should_receive(:error).with("No such app '#{notification.app}' for notification #{notification.id}.")
    Rapns::Daemon::AppRunner.deliver(notification)
  end
end

describe Rapns::Daemon::AppRunner, 'ready' do
  let(:runner1) { stub(:ready? => true) }
  let(:runner2) { stub(:ready? => false) }

  before do
    Rapns::Daemon::AppRunner.all['app1'] = runner1
    Rapns::Daemon::AppRunner.all['app2'] = runner2
  end

  after { Rapns::Daemon::AppRunner.all.clear }

  it 'returns apps that are ready for more notifications' do
    Rapns::Daemon::AppRunner.ready.should == ['app1']
  end
end

describe Rapns::Daemon::AppRunner, 'sync' do
  let(:app) { stub(:key => 'app') }
  let(:new_app) { stub(:key => 'new_app') }
  let(:runner) { stub(:sync => nil, :stop => nil) }
  let(:new_runner) { stub }
  let(:logger) { stub(:error => nil) }
  let(:feedback_config) { stub(:poll => 60) }
  let(:configuration) { stub(:feedback => feedback_config) }

  before do
    Rapns::Daemon.stub(:configuration => configuration, :logger => logger)
    Rapns::Daemon::AppRunner.all['app'] = runner
    Rapns::App.stub(:all => [app])
  end

  after { Rapns::Daemon::AppRunner.all.clear }

  it 'loads all apps' do
    Rapns::App.should_receive(:all)
    Rapns::Daemon::AppRunner.sync
  end

  it 'instructs existing runners to sync' do
    runner.should_receive(:sync).with(app)
    Rapns::Daemon::AppRunner.sync
  end

it 'starts a runner for a new app with a production certificate' do
    new_app.stub(:certificate => 'Apple Production IOS Push Services')
    Rapns::App.stub(:all => [new_app])
    new_runner = stub 
    Rapns::Daemon::AppRunner.should_receive(:new).with(new_app, 'gateway.push.apple.com', 2195,
      'feedback.push.apple.com', 2196, feedback_config.poll).and_return(new_runner)
    new_runner.should_receive(:start)
    Rapns::Daemon::AppRunner.sync
  end

  it 'starts a runner for a new app with a development certificate' do
    new_app.stub(:certificate => 'Apple Development IOS Push Services')
    Rapns::App.stub(:all => [new_app])
    new_runner = stub 
    Rapns::Daemon::AppRunner.should_receive(:new).with(new_app, 'gateway.sandbox.push.apple.com', 2195,
      'feedback.sandbox.push.apple.com', 2196, feedback_config.poll).and_return(new_runner)
    new_runner.should_receive(:start)
    Rapns::Daemon::AppRunner.sync
  end

  it 'logs an error if the environment cannot be determined from the certificate' do
    new_app.stub(:certificate => 'wat')
    Rapns::App.stub(:all => [new_app])
    Rapns::Daemon.logger.should_receive(:error).with("Could not detect environment for app 'new_app'.")
    Rapns::Daemon::AppRunner.sync
  end

  it 'does not attempt to start an AppRunner if the environment could not be detected' do
    new_app.stub(:certificate => 'wat')
    Rapns::App.stub(:all => [new_app])
    Rapns::Daemon::AppRunner.should_not_receive(:new) 
    Rapns::Daemon::AppRunner.sync
  end

  it 'deletes old apps' do
    Rapns::App.stub(:all => [])
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.sync
  end
end