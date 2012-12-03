require "unit_spec_helper"

describe Rapns::Daemon::Feeder do
  let(:config) { stub(:batch_size => 5000) }
  let(:app) { Rapns::Apns::App.create!(:name => 'my_app', :environment => 'development', :certificate => TEST_CERT) }
  let(:notification) { Rapns::Apns::Notification.create!(:device_token => "a" * 64, :app => app) }
  let(:logger) { stub }

  before do
    Rapns::Apns::App.any_instance.stub(:certificate_has_matching_private_key)
    Rapns::Daemon::Feeder.stub(:sleep)
    Rapns::Daemon::Feeder.stub(:interruptible_sleep)
    Rapns::Daemon.stub(:logger => logger, :config => config)
    Rapns::Daemon::Feeder.instance_variable_set("@stop", true)
  end

  def start
    Rapns::Daemon::Feeder.start(0)
  end

  it "checks for new notifications with the ability to reconnect the database" do
    Rapns::Daemon::Feeder.should_receive(:with_database_reconnect_and_retry)
    start
  end

  it 'loads notifications in batches' do
    relation = stub.as_null_object
    relation.should_receive(:limit).with(5000)
    Rapns::Notification.stub(:ready_for_delivery => relation)
    start
  end

  it "enqueue the notification" do
    notification.update_attributes!(:delivered => false)
    Rapns::Daemon::AppRunner.should_receive(:enqueue).with(notification)
    start
  end

  it 'does not enqueue the notification if the app runner is still processing the previous batch' do
    Rapns::Daemon::AppRunner.should_not_receive(:enqueue)
    start
  end

  it "enqueues an undelivered notification without deliver_after set" do
    notification.update_attributes!(:delivered => false, :deliver_after => nil)
    Rapns::Daemon::AppRunner.should_receive(:enqueue).with(notification)
    start
  end

  it "enqueues a notification with a deliver_after time in the past" do
    notification.update_attributes!(:delivered => false, :deliver_after => 1.hour.ago)
    Rapns::Daemon::AppRunner.should_receive(:enqueue).with(notification)
    start
  end

  it "does not enqueue a notification with a deliver_after time in the future" do
    notification.update_attributes!(:delivered => false, :deliver_after => 1.hour.from_now)
    Rapns::Daemon::AppRunner.should_not_receive(:enqueue)
    start
  end

  it "does not enqueue a previously delivered notification" do
    notification.update_attributes!(:delivered => true, :delivered_at => Time.now)
    Rapns::Daemon::AppRunner.should_not_receive(:enqueue)
    start
  end

  it "does not enqueue a notification that has previously failed delivery" do
    notification.update_attributes!(:delivered => false, :failed => true)
    Rapns::Daemon::AppRunner.should_not_receive(:enqueue)
    start
  end

  it "logs errors" do
    e = StandardError.new("bork")
    Rapns::Notification.stub(:ready_for_delivery).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    start
  end

  it "interrupts sleep when stopped" do
    Rapns::Daemon::Feeder.should_receive(:interrupt_sleep)
    Rapns::Daemon::Feeder.stop
  end

  it "enqueues notifications when started" do
    Rapns::Daemon::Feeder.should_receive(:enqueue_notifications).at_least(:once)
    Rapns::Daemon::Feeder.stub(:loop).and_yield
    start
  end

  it "sleeps for the given period" do
    Rapns::Daemon::Feeder.should_receive(:interruptible_sleep).with(2)
    Rapns::Daemon::Feeder.stub(:loop).and_yield
    Rapns::Daemon::Feeder.start(2)
  end
end
