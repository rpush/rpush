shared_examples_for 'an DeliveryHandler subclass' do
  it 'logs all delivery errors' do
    logger = stub
    Rapns.stub(:logger => logger)
    error = StandardError.new
    delivery_handler.stub(:deliver).and_raise(error)
    Rapns.logger.should_receive(:error).with(error)
    delivery_handler.send(:handle_next_notification)
  end

  it 'reflects an exception' do
    Rapns.stub(:logger => stub(:error => nil))
    error = StandardError.new
    delivery_handler.stub(:deliver).and_raise(error)
    delivery_handler.should_receive(:reflect).with(:error, error)
    delivery_handler.send(:handle_next_notification)
  end

  it "instructs the queue to wakeup the thread when told to stop" do
    thread = stub(:join => nil)
    Thread.stub(:new => thread)
    queue.should_receive(:wakeup).with(thread)
    delivery_handler.start
    delivery_handler.stop
  end

  describe "when being stopped" do
    before { queue.pop }

    it "does not attempt to deliver a notification when a DeliveryQueue::::WakeupError is raised" do
      queue.stub(:pop).and_raise(Rapns::Daemon::DeliveryQueue::WakeupError)
      delivery_handler.should_not_receive(:deliver)
      delivery_handler.send(:handle_next_notification)
    end
  end
end
