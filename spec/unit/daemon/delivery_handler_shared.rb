shared_examples_for 'an DeliveryHandler subclass' do
  it 'logs all delivery errors' do
    logger = stub
    Rapns.stub(:logger => logger)
    error = StandardError.new
    delivery_handler.stub(:deliver).and_raise(error)
    Rapns.logger.should_receive(:error).with(error)
    delivery_handler.start
    delivery_handler.stop
  end

  it 'reflects an exception' do
    Rapns.stub(:logger => stub(:error => nil))
    error = StandardError.new
    delivery_handler.stub(:deliver).and_raise(error)
    delivery_handler.should_receive(:reflect).with(:error, error)
    delivery_handler.start
    delivery_handler.stop
  end

  it 'instructs the batch that the notification has been processed' do
    batch.should_receive(:notification_processed)
    delivery_handler.start
    delivery_handler.stop
  end

  it "instructs the queue to wakeup the thread when told to stop" do
    thread = stub(:join => nil)
    Thread.stub(:new => thread)
    queue.should_receive(:push).with(Rapns::Daemon::DeliveryHandler::WAKEUP)
    delivery_handler.start
    delivery_handler.stop
  end

  describe "when being stopped" do
    before { queue.pop }

    it "does not attempt to deliver a notification when a WAKEUP is dequeued" do
      queue.stub(:pop).and_return(Rapns::Daemon::DeliveryHandler::WAKEUP)
      delivery_handler.should_not_receive(:deliver)
      delivery_handler.send(:handle_next_notification)
    end
  end
end
