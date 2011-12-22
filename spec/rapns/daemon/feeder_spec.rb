require "spec_helper"

describe Rapns::Daemon::Feeder do
  before do
    Rapns::Daemon::Feeder.stub(:sleep)
    Rapns::Daemon::Feeder.stub(:interruptible_sleep)
    @notification = Rapns::Notification.create!(:device_token => "a" * 64)
    @logger = mock("Logger", :info => nil, :error => nil, :warn => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
    @queue = mock(:push => nil, :notifications_processed? => true)
    Rapns::Daemon.stub(:delivery_queue).and_return(@queue)
    Rapns::Daemon.stub(:configuration => mock("Configuration", :push => stub(:poll => 2)))
    Rapns::Daemon::Feeder.instance_variable_set("@stop", false)
  end

  it "should reconnect to the database when daemonized" do
    Rapns::Daemon::Feeder.stub(:loop)
    Rapns::Daemon::Feeder.should_receive(:reconnect_database)
    Rapns::Daemon::Feeder.start(false)
  end

  it "should check for new notifications with the ability to reconnect the database" do
    Rapns::Daemon::Feeder.should_receive(:with_database_reconnect_and_retry)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should not reconnect to the database when running in the foreground" do
    Rapns::Daemon::Feeder.stub(:loop)
    Rapns::Daemon::Feeder.should_not_receive(:reconnect_database)
    Rapns::Daemon::Feeder.start(true)
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

  it "should not enqueue more notifications if other are still being processed" do
    Rapns::Daemon.delivery_queue.stub(:notifications_processed? => false)
    Rapns::Notification.should_not_receive(:ready_for_delivery)
    Rapns::Daemon.delivery_queue.should_not_receive(:push)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should log errors" do
    e = StandardError.new("bork")
    Rapns::Notification.stub(:ready_for_delivery).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "interrupts sleep when stopped" do
    Rapns::Daemon::Feeder.should_receive(:interrupt_sleep)
    Rapns::Daemon::Feeder.stop
  end

  it "enqueues notifications when started" do
    Rapns::Daemon::Feeder.should_receive(:enqueue_notifications).at_least(:once)
    Rapns::Daemon::Feeder.stub(:loop).and_yield
    Rapns::Daemon::Feeder.start(true)
  end

  it "should sleep for the given period" do
    Rapns::Daemon::Feeder.should_receive(:interruptible_sleep).with(2)
    Rapns::Daemon::Feeder.stub(:loop).and_yield
    Rapns::Daemon::Feeder.start(true)
  end
end