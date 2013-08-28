shared_examples_for 'an DeliveryHandler subclass' do
  def run_delivery_handler
    delivery_handler.start
    delivery_handler.stop
    delivery_handler.wakeup
    delivery_handler.wait
  end

  it 'logs all delivery errors' do
    logger = double
    Rapns.stub(:logger => logger)
    error = StandardError.new
    delivery_handler.stub(:deliver).and_raise(error)
    Rapns.logger.should_receive(:error).with(error)
    run_delivery_handler
  end

  it 'reflects an exception' do
    Rapns.stub(:logger => double(:error => nil))
    error = StandardError.new
    delivery_handler.stub(:deliver).and_raise(error)
    delivery_handler.should_receive(:reflect).with(:error, error)
    run_delivery_handler
  end

  it 'instructs the batch that the notification has been processed' do
    batch.should_receive(:notification_processed)
    run_delivery_handler
  end

  it "instructs the queue to wakeup the thread when told to stop" do
    queue.should_receive(:push).with(Rapns::Daemon::DeliveryHandler::WAKEUP).and_call_original
    run_delivery_handler
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
