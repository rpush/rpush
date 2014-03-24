require 'unit_spec_helper'

module Rpush
  module AppRunnerSpecService
    class App < Rpush::App
    end
  end

  module Daemon
    module AppRunnerSpecService
      extend ServiceConfigMethods

      class ServiceLoop
        def initialize(app)
        end

        def start
        end

        def stop
        end
      end

      dispatcher :http
      loops ServiceLoop

      class Delivery
      end
    end
  end
end

describe Rpush::Daemon::AppRunner, 'stop' do
  let(:runner) { double }
  before { Rpush::Daemon::AppRunner.runners['app'] = runner }
  after { Rpush::Daemon::AppRunner.runners.clear }

  it 'stops all runners' do
    runner.should_receive(:stop)
    Rpush::Daemon::AppRunner.stop
  end
end

describe Rpush::Daemon::AppRunner, 'enqueue' do
  let(:runner) { double(:enqueue => nil) }
  let(:notification1) { double(:app_id => 1) }
  let(:notification2) { double(:app_id => 2) }
  let(:logger) { double(Rpush::Logger, :error => nil) }

  before do
    Rpush.stub(:logger => logger)
    Rpush::Daemon::AppRunner.runners[1] = runner
  end

  after { Rpush::Daemon::AppRunner.runners.clear }

  it 'batches notifications by app' do
    batch = double.as_null_object
    Rpush::Daemon::Batch.stub(:new => batch)
    Rpush::Daemon::Batch.should_receive(:new).with([notification1])
    Rpush::Daemon::Batch.should_receive(:new).with([notification2])
    Rpush::Daemon::AppRunner.enqueue([notification1, notification2])
  end

  it 'enqueues each batch' do
    runner.should_receive(:enqueue).with(kind_of(Rpush::Daemon::Batch))
    Rpush::Daemon::AppRunner.enqueue([notification1])
  end

  it 'logs an error if there is no runner to deliver the notification' do
    notification1.stub(:app_id => 2, :id => 123)
    notification2.stub(:app_id => 2, :id => 456)
    logger.should_receive(:error).with("No such app '#{notification1.app_id}' for notifications 123, 456.")
    Rpush::Daemon::AppRunner.enqueue([notification1, notification2])
  end
end

describe Rpush::Daemon::AppRunner, 'sync' do
  let(:app) { double(Rpush::AppRunnerSpecService::App, :name => 'test') }
  let(:new_app) { double(Rpush::AppRunnerSpecService::App, :name => 'new_test') }
  let(:runner) { double(:sync => nil, :stop => nil, :start => nil) }
  let(:logger) { double(Rpush::Logger, :error => nil, :warn => nil) }
  let(:queue) { Queue.new }
  let(:store) { double(all_apps: [app]) }

  before do
    app.stub(:id => 1)
    new_app.stub(:id => 2)
    Queue.stub(:new => queue)
    Rpush::Daemon::AppRunner.runners[app.id] = runner
    Rpush.stub(:logger => logger)
    Rpush::Daemon.stub(store: store)
  end

  after { Rpush::Daemon::AppRunner.runners.clear }

  it 'instructs existing runners to sync' do
    runner.should_receive(:sync).with(app)
    Rpush::Daemon::AppRunner.sync
  end

  it 'starts a runner for a new app' do
    store.stub(all_apps: [app, new_app])
    new_runner = double
    Rpush::Daemon::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    new_runner.should_receive(:start)
    Rpush::Daemon::AppRunner.sync
  end

  it 'deletes old runners' do
    store.stub(all_apps: [])
    runner.should_receive(:stop)
    Rpush::Daemon::AppRunner.sync
  end

  it 'logs an error if the runner could not be started' do
    store.stub(all_apps: [app, new_app])
    new_runner = double
    Rpush::Daemon::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    new_runner.stub(:start).and_raise(StandardError)
    Rpush.logger.should_receive(:error)
    Rpush::Daemon::AppRunner.sync
  end

  it 'reflects errors if the runner could not be started' do
    store.stub(all_apps: [app, new_app])
    new_runner = double
    Rpush::Daemon::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    e = StandardError.new
    new_runner.stub(:start).and_raise(e)
    Rpush::Daemon::AppRunner.should_receive(:reflect).with(:error, e)
    Rpush::Daemon::AppRunner.sync
  end
end

describe Rpush::Daemon::AppRunner, 'debug' do
  let(:app) { double(Rpush::AppRunnerSpecService::App, :id => 1, :name => 'test', :connections => 1,
    :environment => 'development', :certificate => TEST_CERT, :service_name => 'app_runner_spec_service') }
  let(:logger) { double(Rpush::Logger, :info => nil) }
  let(:store) { double(all_apps: [app]) }

  before do
    Rpush::Daemon.stub(config: {}, store: store)
    Rpush.stub(:logger => logger)
    Rpush::Daemon::AppRunner.sync
  end

  after { Rpush::Daemon::AppRunner.runners.clear }

  it 'prints debug app states to the log' do
    Rpush.logger.should_receive(:info).with("\ntest:\n  dispatchers: 1\n  queued: 0\n  batch size: 0\n  batch processed: 0\n  idle: true\n")
    Rpush::Daemon::AppRunner.debug
  end
end

describe Rpush::Daemon::AppRunner, 'idle' do
  let(:app) { double(Rpush::AppRunnerSpecService::App, :name => 'test', :connections => 1,
    :environment => 'development', :certificate => TEST_CERT, :id => 1,
    :service_name => 'app_runner_spec_service') }
  let(:logger) { double(Rpush::Logger, :info => nil) }
  let(:store) { double(all_apps: [app]) }

  before do
    Rpush::Daemon.stub(store: store)
    Rpush.stub(:logger => logger)
    Rpush::Daemon::AppRunner.sync
  end

  after { Rpush::Daemon::AppRunner.runners.clear }

  it 'returns idle runners' do
    runner = Rpush::Daemon::AppRunner.runners[app.id]
    Rpush::Daemon::AppRunner.idle.should eq [runner]
  end
end

describe Rpush::Daemon::AppRunner, 'wait' do
  let(:app) { double(Rpush::AppRunnerSpecService::App, :id => 1, :name => 'test',
    :connections => 1, :environment => 'development', :certificate => TEST_CERT,
    :service_name => 'app_runner_spec_service') }
  let(:logger) { double(Rpush::Logger, :info => nil) }
  let(:store) { double(all_apps: [app]) }

  before do
    Rpush::Daemon.stub(store: store)
    Rpush.stub(:logger => logger)
    Rpush::Daemon::AppRunner.sync
  end

  after { Rpush::Daemon::AppRunner.runners.clear }

  it 'waits until all runners are idle' do
    Rpush::Daemon::AppRunner.runners.count.should eq 1
    Timeout.timeout(5) { Rpush::Daemon::AppRunner.wait }
  end
end

describe Rpush::Daemon::AppRunner do
  let(:app) { double(Rpush::AppRunnerSpecService::App, :environment => :sandbox,
    :connections => 1, :service_name => 'app_runner_spec_service',
    :name => 'test') }
  let(:runner) { Rpush::Daemon::AppRunner.new(app) }
  let(:logger) { double(Rpush::Logger, :info => nil) }
  let(:queue) { Queue.new }
  let(:dispatcher_loop_collection) { Rpush::Daemon::DispatcherLoopCollection.new }
  let(:service_loop) { double(Rpush::Daemon::AppRunnerSpecService::ServiceLoop,
    :start => nil, :stop => nil) }
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord, release_connection: nil) }

  before do
    Rpush::Daemon.stub(store: store)
    Rpush::Daemon::AppRunnerSpecService::ServiceLoop.stub(:new => service_loop)
    Queue.stub(:new => queue)
    Rpush.stub(:logger => logger)
    Rpush::Daemon::DispatcherLoopCollection.stub(:new => dispatcher_loop_collection)
  end

  describe 'start' do
    it 'starts a delivery dispatcher for each connection' do
      app.stub(:connections => 2)
      runner.start
      runner.num_dispatchers.should eq 2
    end

    it 'starts the loops' do
      service_loop.should_receive(:start)
      runner.start
    end
  end

  describe 'enqueue' do
    let(:notification) { double }
    let(:batch) { double(:notifications => [notification]) }

    it 'enqueues the batch' do
      queue.should_receive(:push).with([notification, batch])
      runner.enqueue(batch)
    end

    it 'reflects the notification has been enqueued' do
      runner.should_receive(:reflect).with(:notification_enqueued, notification)
      runner.enqueue(batch)
    end
  end

  describe 'stop' do
    before { runner.start }

    it 'stops the delivery dispatchers' do
      dispatcher_loop_collection.should_receive(:stop)
      runner.stop
    end

    it 'stop the loops' do
      service_loop.should_receive(:stop)
      runner.stop
    end
  end

  describe 'idle?' do
    it 'is idle if all notifications have been processed' do
      runner.batch = double(:complete? => true)
      runner.idle?.should be_true
    end

    it 'is idle if the runner has no associated batch' do
      runner.batch = nil
      runner.idle?.should be_true
    end

    it 'is not idle if not all notifications have been processed' do
      runner.batch = double(:complete? => false)
      runner.idle?.should be_false
    end
  end

  describe 'sync' do
    before { runner.start }

    it 'reduces the number of dispatchers if needed' do
      app.stub(:connections => 0)
      expect { runner.sync(app) }.to change(runner, :num_dispatchers).to(0)
    end

    it 'increases the number of dispatchers if needed' do
      app.stub(:connections => 2)
      expect { runner.sync(app) }.to change(runner, :num_dispatchers).to(2)
    end
  end
end
