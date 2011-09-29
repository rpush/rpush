require "spec_helper"

describe Rapns::Daemon::Feeder do
  before do
    Rapns::Daemon::Feeder.stub(:sleep)
    @notification = Rapns::Notification.create!(:device_token => "a" * 64)
    @logger = mock("Logger", :info => nil, :error => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
    @queue = mock(:push => nil, :wait_until_empty => nil)
    Rapns::Daemon.stub(:delivery_queue).and_return(@queue)
    Rapns::Daemon.stub(:configuration => mock("Configuration", :poll => 2))
  end

  it "should enqueue an undelivered notification" do
    @notification.update_attributes!(:delivered => false)
    Rapns::Daemon.delivery_queue.should_receive(:push)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should enqueue an undelivered notification without deliver_after set" do
    @notification.update_attributes!(:delivered => false, :deliver_after => nil)
    Rapns::Daemon.delivery_queue.should_receive(:push)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should enqueue a notification with a deliver_after time in the past" do
    @notification.update_attributes!(:delivered => false, :deliver_after => 1.hour.ago)
    Rapns::Daemon.delivery_queue.should_receive(:push)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should not enqueue a notification with a deliver_after time in the future" do
    @notification.update_attributes!(:delivered => false, :deliver_after => 1.hour.from_now)
    Rapns::Daemon.delivery_queue.should_not_receive(:push)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should not enqueue a previously delivered notification" do
    @notification.update_attributes!(:delivered => true, :delivered_at => Time.now)
    Rapns::Daemon.delivery_queue.should_not_receive(:push)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should not enqueue a notification that has previously failed delivery" do
    @notification.update_attributes!(:delivered => false, :failed => true)
    Rapns::Daemon.delivery_queue.should_not_receive(:push)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should sleep for the given period" do
    Rapns::Daemon::Feeder.should_receive(:sleep).with(2)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should wait for the delivery queue to be emptied" do
    Rapns::Daemon.delivery_queue.should_receive(:wait_until_empty)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should log errors" do
    e = StandardError.new("bork")
    Rapns::Notification.stub(:ready_for_delivery).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    Rapns::Daemon::Feeder.enqueue_notifications
  end
end