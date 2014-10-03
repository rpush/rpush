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

describe Rpush::Daemon::AppRunner, 'enqueue' do
  let(:app) { double(id: 1, name: 'Test', connections: 1) }
  let(:notification) { double(app_id: 1) }
  let(:runner) { double(Rpush::Daemon::AppRunner, enqueue: nil, start: nil, stop: nil) }
  let(:logger) { double(Rpush::Logger, error: nil, info: nil) }

  before do
    Rpush.stub(logger: logger)
    Rpush::Daemon::ProcTitle.stub(:update)
    Rpush::Daemon::AppRunner.stub(new: runner)
    Rpush::Daemon::AppRunner.start_app(app)
  end

  after { Rpush::Daemon::AppRunner.stop }

  it 'enqueues notifications on the runner' do
    runner.should_receive(:enqueue).with([notification])
    Rpush::Daemon::AppRunner.enqueue([notification])
  end

  it 'starts the app if a runner does not exist' do
    notification = double(app_id: 3)
    new_app = double(Rpush::App, id: 3, name: 'NewApp', connections: 1)
    Rpush::Daemon.store = double(app: new_app)
    Rpush::Daemon::AppRunner.enqueue([notification])
    Rpush::Daemon::AppRunner.app_running?(new_app).should be_true
  end
end

describe Rpush::Daemon::AppRunner, 'start_app' do
  let(:app) { double(id: 1, name: 'test', connections: 1) }
  let(:runner) { double(Rpush::Daemon::AppRunner, enqueue: nil, start: nil, stop: nil) }
  let(:logger) { double(Rpush::Logger, error: nil, info: nil) }

  before do
    Rpush.stub(logger: logger)
  end

  it 'logs an error if the runner could not be started' do
    Rpush::Daemon::AppRunner.should_receive(:new).with(app).and_return(runner)
    runner.stub(:start).and_raise(StandardError)
    Rpush.logger.should_receive(:error)
    Rpush::Daemon::AppRunner.start_app(app)
  end
end

describe Rpush::Daemon::AppRunner, 'debug' do
  let(:app) do
    double(Rpush::AppRunnerSpecService::App, id: 1, name: 'test', connections: 1,
      environment: 'development', certificate: TEST_CERT, service_name: 'app_runner_spec_service')
  end
  let(:logger) { double(Rpush::Logger, info: nil) }
  let(:store) { double(all_apps: [app], release_connection: nil) }

  before do
    Rpush::Daemon.stub(config: {}, store: store)
    Rpush.stub(logger: logger)
    Rpush::Daemon::AppRunner.start_app(app)
  end

  after { Rpush::Daemon::AppRunner.stop_app(app.id) }

  it 'prints debug app states to the log' do
    Rpush.logger.should_receive(:info).with(kind_of(String))
    Rpush::Daemon::AppRunner.debug
  end
end

describe Rpush::Daemon::AppRunner do
  let(:app) do
    double(Rpush::AppRunnerSpecService::App, environment: :sandbox,
      connections: 1, service_name: 'app_runner_spec_service', name: 'test')
  end
  let(:runner) { Rpush::Daemon::AppRunner.new(app) }
  let(:logger) { double(Rpush::Logger, info: nil) }
  let(:queue) { Queue.new }
  let(:service_loop) { double(Rpush::Daemon::AppRunnerSpecService::ServiceLoop, start: nil, stop: nil) }
  let(:dispatcher_loop) { double(Rpush::Daemon::DispatcherLoop, stop: nil, start: nil) }
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord, release_connection: nil) }

  before do
    Rpush::Daemon::DispatcherLoop.stub(new: dispatcher_loop)
    Rpush::Daemon.stub(store: store)
    Rpush::Daemon::AppRunnerSpecService::ServiceLoop.stub(new: service_loop)
    Queue.stub(new: queue)
    Rpush.stub(logger: logger)
  end

  describe 'start' do
    it 'starts a delivery dispatcher for each connection' do
      app.stub(connections: 2)
      runner.start
      runner.num_dispatcher_loops.should eq 2
    end

    it 'starts the dispatcher loop' do
      dispatcher_loop.should_receive(:start)
      runner.start
    end

    it 'starts the loops' do
      service_loop.should_receive(:start)
      runner.start
    end
  end

  describe 'enqueue' do
    let(:notification) { double }

    it 'enqueues the batch' do
      queue.should_receive(:push) do |queue_payload|
        queue_payload.notification.should eq notification
        queue_payload.batch.should_not be_nil
      end
      runner.enqueue([notification])
    end

    it 'reflects the notification has been enqueued' do
      runner.should_receive(:reflect).with(:notification_enqueued, notification)
      runner.enqueue([notification])
    end

    describe 'a service that batches deliveries' do
      before do
        runner.send(:service).stub(batch_deliveries?: true)
      end

      describe '1 notification with more than one dispatcher loop' do
        it 'does not raise ArgumentError: invalid slice size' do
          # https://github.com/rpush/rpush/issues/57
          runner.stub(:num_dispatcher_loops).and_return(2)
          runner.enqueue([notification])
        end
      end
    end
  end

  describe 'stop' do
    before { runner.start }

    it 'stops the delivery dispatchers' do
      dispatcher_loop.should_receive(:stop)
      runner.stop
    end

    it 'stop the loops' do
      service_loop.should_receive(:stop)
      runner.stop
    end
  end
end
