require 'unit_spec_helper'

describe Rpush::Daemon::DispatcherLoop do
  def run_dispatcher_loop
    dispatcher_loop.start
    dispatcher_loop.stop
  end

  let(:notification) { double }
  let(:batch) { double(notification_processed: nil) }
  let(:queue) { Queue.new }
  let(:dispatcher) { double(dispatch: nil, cleanup: nil) }
  let(:dispatcher_loop) { Rpush::Daemon::DispatcherLoop.new(queue, dispatcher) }
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord, release_connection: nil) }

  before do
    Rpush::Daemon.stub(store: store)
    queue.push([notification, batch])
  end

  it 'logs errors' do
    logger = double
    Rpush.stub(logger: logger)
    error = StandardError.new
    dispatcher.stub(:dispatch).and_raise(error)
    Rpush.logger.should_receive(:error).with(error)
    run_dispatcher_loop
  end

  it 'reflects an exception' do
    Rpush.stub(logger: double(error: nil))
    error = StandardError.new
    dispatcher.stub(:dispatch).and_raise(error)
    dispatcher_loop.should_receive(:reflect).with(:error, error)
    run_dispatcher_loop
  end

  describe 'stop' do
    before do
      queue.clear
    end

    it 'instructs the dispatcher to cleanup' do
      dispatcher.should_receive(:cleanup)
      run_dispatcher_loop
    end

    it 'releases the store connection' do
      Rpush::Daemon.store.should_receive(:release_connection)
      run_dispatcher_loop
    end
  end
end
