require 'unit_spec_helper'

module Rapns
  module AppRunnerSpecService
    class App < Rapns::App
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
  let(:logger) { double(Rapns::Logger, :error => nil) }

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
  let(:app) { double(Rapns::AppRunnerSpecService::App, :name => 'test') }
  let(:new_app) { double(Rapns::AppRunnerSpecService::App, :name => 'new_test') }
  let(:runner) { double(:sync => nil, :stop => nil, :start => nil) }
  let(:logger) { double(Rapns::Logger, :error => nil, :warn => nil) }
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
    Rapns::Daemon::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    new_runner.should_receive(:start)
    Rapns::Daemon::AppRunner.sync
  end

  it 'deletes old runners' do
    Rapns::App.stub(:all => [])
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.sync
  end

  it 'logs an error if the runner could not be started' do
    Rapns::App.stub(:all => [app, new_app])
    new_runner = double
    Rapns::Daemon::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    new_runner.stub(:start).and_raise(StandardError)
    Rapns.logger.should_receive(:error)
    Rapns::Daemon::AppRunner.sync
  end

  it 'reflects errors if the runner could not be started' do
    Rapns::App.stub(:all => [app, new_app])
    new_runner = double
    Rapns::Daemon::AppRunner.should_receive(:new).with(new_app).and_return(new_runner)
    e = StandardError.new
    new_runner.stub(:start).and_raise(e)
    Rapns::Daemon::AppRunner.should_receive(:reflect).with(:error, e)
    Rapns::Daemon::AppRunner.sync
  end
end

describe Rapns::Daemon::AppRunner, 'debug' do
  let(:app) { double(Rapns::AppRunnerSpecService::App, :id => 1, :name => 'test', :connections => 1,
    :environment => 'development', :certificate => TEST_CERT, :service_name => 'app_runner_spec_service') }
  let(:logger) { double(Rapns::Logger, :info => nil) }

  before do
    Rapns::App.stub(:all => [app])
    Rapns::Daemon.stub(:config => {})
    Rapns.stub(:logger => logger)
    Rapns::Daemon::AppRunner.sync
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'prints debug app states to the log' do
    Rapns.logger.should_receive(:info).with("\ntest:\n  dispatchers: 1\n  queued: 0\n  batch size: 0\n  batch processed: 0\n  idle: true\n")
    Rapns::Daemon::AppRunner.debug
  end
end

describe Rapns::Daemon::AppRunner, 'idle' do
  let(:app) { double(Rapns::AppRunnerSpecService::App, :name => 'test', :connections => 1,
    :environment => 'development', :certificate => TEST_CERT, :id => 1,
    :service_name => 'app_runner_spec_service') }
  let(:logger) { double(Rapns::Logger, :info => nil) }

  before do
    Rapns::App.stub(:all => [app])
    Rapns.stub(:logger => logger)
    Rapns::Daemon::AppRunner.sync
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'returns idle runners' do
    runner = Rapns::Daemon::AppRunner.runners[app.id]
    Rapns::Daemon::AppRunner.idle.should eq [runner]
  end
end

describe Rapns::Daemon::AppRunner, 'wait' do
  let(:app) { double(Rapns::AppRunnerSpecService::App, :id => 1, :name => 'test',
    :connections => 1, :environment => 'development', :certificate => TEST_CERT,
    :service_name => 'app_runner_spec_service') }
  let(:logger) { double(Rapns::Logger, :info => nil) }

  before do
    Rapns::App.stub(:all => [app])
    Rapns.stub(:logger => logger)
    Rapns::Daemon::AppRunner.sync
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'waits until all runners are idle' do
    Rapns::Daemon::AppRunner.runners.count.should eq 1
    Timeout.timeout(5) { Rapns::Daemon::AppRunner.wait }
  end
end

describe Rapns::Daemon::AppRunner do
  let(:app) { double(Rapns::AppRunnerSpecService::App, :environment => :sandbox,
    :connections => 1, :service_name => 'app_runner_spec_service',
    :name => 'test') }
  let(:runner) { Rapns::Daemon::AppRunner.new(app) }
  let(:logger) { double(Rapns::Logger, :info => nil) }
  let(:queue) { Queue.new }
  let(:dispatcher_loop_collection) { Rapns::Daemon::DispatcherLoopCollection.new }
  let(:service_loop) { double(Rapns::Daemon::AppRunnerSpecService::ServiceLoop,
    :start => nil, :stop => nil) }

  before do
    Rapns::Daemon::AppRunnerSpecService::ServiceLoop.stub(:new => service_loop)
    Queue.stub(:new => queue)
    Rapns.stub(:logger => logger)
    Rapns::Daemon::DispatcherLoopCollection.stub(:new => dispatcher_loop_collection)
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
