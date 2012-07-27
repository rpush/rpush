require 'unit_spec_helper'

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
  let(:logger) { stub(:error => nil) }

  before do
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

  it 'starts a runner for a new app' do
    Rapns::App.stub(:all => [app, new_app])
    new_runner = stub
    new_app.should_receive(:new_runner).and_return(new_runner)
    new_runner.should_receive(:start)
    Rapns::Daemon::AppRunner.sync
  end

  it 'deletes old apps' do
    Rapns::App.stub(:all => [])
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.sync
  end
end