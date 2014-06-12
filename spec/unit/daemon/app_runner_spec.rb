require 'unit_spec_helper'
require 'rpush/daemon/store/active_record'

module Rpush
  module AppRunnerSpecService
    class App < Rpush::App
    end
  end

  module Daemon
    module AppRunnerSpecService
      extend ServiceConfigMethods

      class ServiceLoop
        def initialize(*)
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
  let(:runner) { double(enqueue: nil) }
  let(:notification1) { double(app_id: 1) }
  let(:notification2) { double(app_id: 2) }
  let(:logger) { double(Rpush::Logger, error: nil, info: nil) }

  before do
    Rpush.stub(logger: logger)
    Rpush::Daemon::AppRunner.runners[1] = runner
    Rpush::Daemon::AppRunner.runners[2] = runner
  end

  after { Rpush::Daemon::AppRunner.runners.clear }

  it 'batches notifications by app' do
    batch = double.as_null_object
    Rpush::Daemon::Batch.stub(new: batch)
    Rpush::Daemon::Batch.should_receive(:new).with([notification1])
    Rpush::Daemon::Batch.should_receive(:new).with([notification2])
    Rpush::Daemon::AppRunner.enqueue([notification1, notification2])
  end

  it 'enqueues each batch' do
    runner.should_receive(:enqueue).with(kind_of(Rpush::Daemon::Batch))
    Rpush::Daemon::AppRunner.enqueue([notification1])
  end

  it 'syncs the app if a runner does not exist' do
    Rpush::Daemon::AppRunner.runners[3].should be_nil
    notification = double(app_id: 3)
    app = double(Rpush::App, id: 3, connections: 1, service_name: 'app_runner_spec_service', environment: 'sandbox', certificate: TEST_CERT, password: nil, name: 'test')
    Rpush::Daemon.store = double(app: app)
    Rpush::Daemon::AppRunner.enqueue([notification])
    Rpush::Daemon::AppRunner.runners[3].should_not be_nil
  end
end

describe Rpush::Daemon::AppRunner, 'sync' do
  let(:app) { double(Rpush::AppRunnerSpecService::App, name: 'test') }
  let(:new_app) { double(Rpush::AppRunnerSpecService::App, name: 'new_test') }
  let(:runner) { double(sync: nil, stop: nil, start: nil) }
  let(:logger) { double(Rpush::Logger, error: nil, warn: nil) }
  let(:queue) { Queue.new }
  let(:store) { double(all_apps: [app]) }

  before do
    app.stub(id: 1)
    new_app.stub(id: 2)
    Queue.stub(new: queue)
    Rpush::Daemon::AppRunner.runners[app.id] = runner
    Rpush.stub(logger: logger)
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
  let(:app) do double(Rpush::AppRunnerSpecService::App, id: 1, name: 'test', connections: 1,
                                                        environment: 'development', certificate: TEST_CERT, service_name: 'app_runner_spec_service')
  end
  let(:logger) { double(Rpush::Logger, info: nil) }
  let(:store) { double(all_apps: [app]) }

  before do
    Rpush::Daemon.stub(config: {}, store: store)
    Rpush.stub(logger: logger)
    Rpush::Daemon::AppRunner.sync
  end

  after { Rpush::Daemon::AppRunner.runners.clear }

  it 'prints debug app states to the log' do
    Rpush.logger.should_receive(:info).with("\ntest:\n  dispatchers: 1\n  queued: 0\n")
    Rpush::Daemon::AppRunner.debug
  end
end

describe Rpush::Daemon::AppRunner do
  let(:app) do double(Rpush::AppRunnerSpecService::App, environment: :sandbox,
                                                        connections: 1, service_name: 'app_runner_spec_service',
                                                        name: 'test')
  end
  let(:runner) { Rpush::Daemon::AppRunner.new(app) }
  let(:logger) { double(Rpush::Logger, info: nil) }
  let(:queue) { Queue.new }
  let(:dispatcher_loop_collection) { Rpush::Daemon::DispatcherLoopCollection.new }
  let(:service_loop) do double(Rpush::Daemon::AppRunnerSpecService::ServiceLoop,
                               start: nil, stop: nil)
  end
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord, release_connection: nil) }

  before do
    Rpush::Daemon.stub(store: store)
    Rpush::Daemon::AppRunnerSpecService::ServiceLoop.stub(new: service_loop)
    Queue.stub(new: queue)
    Rpush.stub(logger: logger)
    Rpush::Daemon::DispatcherLoopCollection.stub(new: dispatcher_loop_collection)
  end

  describe 'start' do
    it 'starts a delivery dispatcher for each connection' do
      app.stub(connections: 2)
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
    let(:batch) { double(notifications: [notification]) }

    before do
      batch.stub(:each_notification).and_yield(notification)
    end

    it 'enqueues the batch' do
      queue.should_receive(:push) do |queue_payload|
        queue_payload.notification.should eq notification
        queue_payload.batch.should eq batch
      end
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

  describe 'sync' do
    before { runner.start }

    it 'reduces the number of dispatchers if needed' do
      app.stub(connections: 0)
      expect { runner.sync(app) }.to change(runner, :num_dispatchers).to(0)
    end

    it 'increases the number of dispatchers if needed' do
      app.stub(connections: 2)
      expect { runner.sync(app) }.to change(runner, :num_dispatchers).to(2)
    end
  end
end
