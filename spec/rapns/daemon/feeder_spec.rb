require "spec_helper"

describe Rapns::Daemon::Feeder do
  let(:poll) { 2 }
  let(:configuration) { stub(:feeder_batch_size => 5000) }
  let(:notification) { Rapns::Notification.create!(:device_token => "a" * 64, :app => 'my_app') }
  let(:logger) { stub }

  before do
    Rapns::Daemon::Feeder.stub(:sleep)
    Rapns::Daemon::Feeder.stub(:interruptible_sleep)
    Rapns::Daemon.stub(:logger => logger, :configuration => configuration)
    Rapns::Daemon::Feeder.instance_variable_set("@stop", false)
    Rapns::Daemon::AppRunner.stub(:ready => ['my_app'])
    Rapns::Daemon::AppRunner.stub(:ready => ['my_app'])
  end

  it "checks for new notifications with the ability to reconnect the database" do
    Rapns::Daemon::Feeder.should_receive(:with_database_reconnect_and_retry)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it 'loads notifications in batches' do
    relation = stub
    relation.should_receive(:find_each).with(:batch_size => 5000)
    Rapns::Notification.stub(:ready_for_delivery => relation)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "delivers the notification" do
    notification.update_attributes!(:delivered => false)
    Rapns::Daemon::AppRunner.should_receive(:deliver).with(notification)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it 'does not enqueue the notification if the app runner is still processing the previous batch' do
    Rapns::Daemon::AppRunner.stub(:ready => [])
    Rapns::Daemon::AppRunner.should_not_receive(:deliver)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "enqueues an undelivered notification without deliver_after set" do
    notification.update_attributes!(:delivered => false, :deliver_after => nil)
    Rapns::Daemon::AppRunner.should_receive(:deliver).with(notification)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "enqueues a notification with a deliver_after time in the past" do
    notification.update_attributes!(:delivered => false, :deliver_after => 1.hour.ago)
    Rapns::Daemon::AppRunner.should_receive(:deliver).with(notification)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "does not enqueue a notification with a deliver_after time in the future" do
    notification.update_attributes!(:delivered => false, :deliver_after => 1.hour.from_now)
    Rapns::Daemon::AppRunner.should_not_receive(:deliver)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "does not enqueue a previously delivered notification" do
    notification.update_attributes!(:delivered => true, :delivered_at => Time.now)
    Rapns::Daemon::AppRunner.should_not_receive(:deliver)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "does not enqueue a notification that has previously failed delivery" do
    notification.update_attributes!(:delivered => false, :failed => true)
    Rapns::Daemon::AppRunner.should_not_receive(:deliver)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "logs errors" do
    e = StandardError.new("bork")
    Rapns::Notification.stub(:ready_for_delivery).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "interrupts sleep when stopped" do
    Rapns::Daemon::Feeder.should_receive(:interrupt_sleep)
    Rapns::Daemon::Feeder.stop
  end

  describe 'start - postgresql' do
    before do
      Rapns::Notification.connection.stub(:adapter_name => 'PostgreSQL')
      Rapns::Notification.connection.raw_connection.stub(:wait_for_notify)
      Rapns::Daemon::Feeder.stub(:loop).and_yield
    end

    it 'registers the current session as a listener' do
      Rapns::Notification.connection.should_receive(:execute).with('LISTEN rapns')
      Rapns::Daemon::Feeder.start(poll)
    end

    it "enqueues notifications" do
      Rapns::Daemon::Feeder.should_receive(:enqueue_notifications).at_least(:once)
      Rapns::Daemon::Feeder.start(poll)
    end

    it "waits for a notify" do
      Rapns::Notification.connection.raw_connection.should_receive(:wait_for_notify)
      Rapns::Daemon::Feeder.start(poll)
    end
  end

  describe 'start - mysql' do
    before do
      Rapns::Notification.connection.stub(:adapter_name => 'MySQL')
      Rapns::Daemon::Feeder.stub(:loop).and_yield
    end

    it "enqueues notifications" do
      Rapns::Daemon::Feeder.should_receive(:enqueue_notifications).at_least(:once)
      Rapns::Daemon::Feeder.start(poll)
    end

    it "sleeps for the given period" do
      Rapns::Daemon::Feeder.should_receive(:interruptible_sleep).with(poll)
      Rapns::Daemon::Feeder.start(poll)
    end
  end
end