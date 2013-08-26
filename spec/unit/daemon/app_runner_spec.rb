require 'unit_spec_helper'

describe Rapns::Daemon::AppRunner, 'stop' do
  let(:runner) { double }
  before { Rapns::Daemon::AppRunner.runners['app'] = runner }
  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'stops all runners' do
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.stop
  end
end

describe Rapns::Daemon::AppRunner, 'enqueue' do
  let(:runner) { double(:enqueue => nil) }
  let(:notification1) { double(:app_id => 1) }
  let(:notification2) { double(:app_id => 2) }
  let(:logger) { double(:error => nil) }

  before do
    Rapns.stub(:logger => logger)
    Rapns::Daemon::AppRunner.runners[1] = runner
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'batches notifications by app' do
    batch = double.as_null_object
    Rapns::Daemon::Batch.stub(:new => batch)
    Rapns::Daemon::Batch.should_receive(:new).with([notification1])
    Rapns::Daemon::Batch.should_receive(:new).with([notification2])
    Rapns::Daemon::AppRunner.enqueue([notification1, notification2])
  end

  it 'enqueues each batch' do
    runner.should_receive(:enqueue).with(kind_of(Rapns::Daemon::Batch))
    Rapns::Daemon::AppRunner.enqueue([notification1])
  end

  it 'logs an error if there is no runner to deliver the notification' do
    notification1.stub(:app_id => 2, :id => 123)
    notification2.stub(:app_id => 2, :id => 456)
    logger.should_receive(:error).with("No such app '#{notification1.app_id}' for notifications 123, 456.")
    Rapns::Daemon::AppRunner.enqueue([notification1, notification2])
  end
end

describe Rapns::Daemon::AppRunner, 'sync' do
  let(:app) { Rapns::Apns::App.new }
  let(:new_app) { Rapns::Apns::App.new }
  let(:runner) { double(:sync => nil, :stop => nil, :start => nil) }
  let(:logger) { double(:error => nil, :warn => nil) }
  let(:queue) { Queue.new }

  before do
    app.stub(:id => 1)
    new_app.stub(:id => 2)
    Queue.stub(:new => queue)
    Rapns::Daemon::AppRunner.runners[app.id] = runner
    Rapns::App.stub(:all => [app])
    Rapns.stub(:logger => logger)
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
    new_runner = double
    Rapns::Daemon::Apns::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    new_runner.should_receive(:start)
    Rapns::Daemon::AppRunner.sync
  end

  it 'deletes old apps' do
    Rapns::App.stub(:all => [])
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.sync
  end

  it 'logs an error if the app could not be started' do
    Rapns::App.stub(:all => [app, new_app])
    new_runner = double
    Rapns::Daemon::Apns::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    new_runner.stub(:start).and_raise(StandardError)
    Rapns.logger.should_receive(:error)
    Rapns::Daemon::AppRunner.sync
  end

  it 'reflects errors if the app could not be started' do
    Rapns::App.stub(:all => [app, new_app])
    new_runner = double
    Rapns::Daemon::Apns::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    e = StandardError.new
    new_runner.stub(:start).and_raise(e)
    Rapns::Daemon::AppRunner.should_receive(:reflect).with(:error, e)
    Rapns::Daemon::AppRunner.sync
  end
end

describe Rapns::Daemon::AppRunner, 'debug' do
  let!(:app) { Rapns::Apns::App.create!(:name => 'test', :connections => 1,
    :environment => 'development', :certificate => TEST_CERT) }
  let(:logger) { double(:info => nil) }

  before do
    Rapns::Daemon.stub(:config => {})
    Rapns::Daemon::Apns::FeedbackReceiver.stub(:new => double.as_null_object)
    Rapns::Daemon::Apns::Connection.stub(:new => double.as_null_object)
    Rapns.stub(:logger => logger)
    Rapns::Daemon::AppRunner.sync
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'prints debug app states to the log' do
    Rapns.logger.should_receive(:info).with("\ntest:\n  handlers: 1\n  queued: 0\n  batch size: 0\n  batch processed: 0\n  idle: true\n")
    Rapns::Daemon::AppRunner.debug
  end
end

describe Rapns::Daemon::AppRunner, 'idle' do
  let!(:app) { Rapns::Apns::App.create!(:name => 'test', :connections => 1,
    :environment => 'development', :certificate => TEST_CERT) }
  let(:logger) { double(:info => nil) }

  before do
    Rapns.stub(:logger => logger)
    Rapns::Daemon::Apns::FeedbackReceiver.stub(:new => double.as_null_object)
    Rapns::Daemon::Apns::Connection.stub(:new => double.as_null_object)
    Rapns::Daemon::AppRunner.sync
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'returns idle runners' do
    runner = Rapns::Daemon::AppRunner.runners[app.id]
    Rapns::Daemon::AppRunner.idle.should == [runner]
  end
end

describe Rapns::Daemon::AppRunner, 'wait' do
  let!(:app) { Rapns::Apns::App.create!(:name => 'test', :connections => 1,
    :environment => 'development', :certificate => TEST_CERT) }
  let(:logger) { double(:info => nil) }

  before do
    Rapns.stub(:logger => logger)
    Rapns::Daemon::Apns::FeedbackReceiver.stub(:new => double.as_null_object)
    Rapns::Daemon::Apns::Connection.stub(:new => double.as_null_object)
    Rapns::Daemon::AppRunner.sync
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'waits until all runners are idle' do
    Rapns::Daemon::AppRunner.runners.count.should == 1
    Timeout.timeout(5) { Rapns::Daemon::AppRunner.wait }
  end
end
