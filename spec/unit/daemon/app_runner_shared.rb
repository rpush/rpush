shared_examples_for "an AppRunner subclass" do
  let(:queue) { double(:push => nil) }

  before { Queue.stub(:new => queue) }
  after { Rapns::Daemon::AppRunner.runners.clear }

  describe 'start' do
    it 'starts a delivery handler for each connection' do
      handler.should_receive(:start)
      runner.start
    end

    it 'adds the delivery handler to the collection' do
      handler_collection.should_receive(:push).with(handler)
      runner.start
    end

    it 'assigns the queue to the handler' do
      handler.should_receive(:queue=).with(queue)
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

    it 'stops the delivery handlers' do
      handler_collection.should_receive(:stop)
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

    it 'reduces the number of handlers if needed' do
      handler_collection.should_receive(:pop)
      new_app = app_class.new
      new_app.stub(:connections => app.connections - 1)
      runner.sync(new_app)
    end

    it 'increases the number of handlers if needed' do
      runner.should_receive(:start_handler).and_return(handler)
      handler_collection.should_receive(:push).with(handler)
      new_app = app_class.new
      new_app.stub(:connections => app.connections + 1)
      runner.sync(new_app)
    end
  end
end
