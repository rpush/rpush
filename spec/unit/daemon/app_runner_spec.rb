require 'unit_spec_helper'

describe Rapns::Daemon::AppRunner, 'stop' do
  let(:runner) { stub }
  before { Rapns::Daemon::AppRunner.runners['app'] = runner }
  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'stops all runners' do
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.stop
  end
end

describe Rapns::Daemon::AppRunner, 'deliver' do
  let(:runner) { stub }
  let(:notification) { stub(:app_id => 1) }
  let(:logger) { stub(:error => nil) }

  before do
    Rapns::Daemon.stub(:logger => logger)
    Rapns::Daemon::AppRunner.runners[1] = runner
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'enqueues the notification' do
    runner.should_receive(:enqueue).with(notification)
    Rapns::Daemon::AppRunner.enqueue(notification)
  end

  it 'logs an error if there is no runner to deliver the notification' do
    notification.stub(:app_id => 2, :id => 123)
    logger.should_receive(:error).with("No such app '#{notification.app_id}' for notification #{notification.id}.")
    Rapns::Daemon::AppRunner.enqueue(notification)
  end
end

describe Rapns::Daemon::AppRunner, 'sync' do
  let(:app) { Rapns::Apns::App.new }
  let(:new_app) { Rapns::Apns::App.new }
  let(:runner) { stub(:sync => nil, :stop => nil, :start => nil) }
  let(:logger) { stub(:error => nil) }
  let(:queue) { Rapns::Daemon::DeliveryQueue.new }

  before do
    app.stub(:id => 1)
    new_app.stub(:id => 2)
    Rapns::Daemon::DeliveryQueue.stub(:new => queue)
    Rapns::Daemon::AppRunner.runners[app.id] = runner
    Rapns::App.stub(:all => [app])
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'loads all apps' do
    Rapns::App.should_receive(:all)
    Rapns::Daemon::AppRunner.sync
  end

  it 'instructs existing runners to sync' do
    runner.should_receive(:sync).with(app)
    Rapns::Daemon::AppRunner.sync
  end

  it 'starts a runner for a new app' do
    Rapns::App.stub(:all => [app, new_app])
    new_runner = stub
    Rapns::Daemon::Apns::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    new_runner.should_receive(:start)
    Rapns::Daemon::AppRunner.sync
  end

  it 'deletes old apps' do
    Rapns::App.stub(:all => [])
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.sync
  end
end
