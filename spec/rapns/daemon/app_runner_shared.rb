shared_examples_for "an AppRunner subclass" do
  let(:queue) { stub(:notifications_processed? => true, :push => nil) }


  before do
    Rapns::Daemon::DeliveryQueue.stub(:new => queue)
  end

  after { Rapns::Daemon::AppRunner.all.clear }

  describe 'start' do
    it 'starts a delivery handler for each connection' do
      runner.should_receive(:start_handler).once
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
