require "unit_spec_helper"

describe Rpush::Daemon::Feeder do
  let(:config) { double(:batch_size => 5000,
                        :push_poll => 0,
                        :embedded => false,
                        :push => false,
                        :wakeup => nil) }
  let!(:app) { Rpush::Apns::App.create!(:name => 'my_app', :environment => 'development', :certificate => TEST_CERT) }
  let(:notification) { Rpush::Apns::Notification.create!(:device_token => "a" * 64, :app => app) }
  let(:logger) { double }
  let(:interruptible_sleep) { double(:sleep => nil, :interrupt_sleep => nil) }
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord,
      deliverable_notifications: [notification], release_connection: nil) }

  before do
    Rpush.stub(:config => config,:logger => logger)
    Rpush::Daemon.stub(:store => store)
    Rpush::Daemon::Feeder.stub(:stop? => true)
    Rpush::Daemon::AppRunner.stub(:enqueue => nil, :idle => [double(:app => app)])
    Rpush::Daemon::InterruptibleSleep.stub(:new => interruptible_sleep)
  end

  def start_and_stop
    Rpush::Daemon::Feeder.start
    Rpush::Daemon::Feeder.stop
  end

  it 'starts the loop in a new thread if embedded' do
    config.stub(:embedded => true)
    Thread.should_receive(:new).and_yield
    Rpush::Daemon::Feeder.should_receive(:feed_forever)
    start_and_stop
  end

  it 'loads deliverable notifications' do
    Rpush::Daemon.store.should_receive(:deliverable_notifications).with([app])
    start_and_stop
  end

  it 'does not attempt to load deliverable notifications if there are no idle runners' do
    Rpush::Daemon::AppRunner.stub(:idle => [])
    Rpush::Daemon.store.should_not_receive(:deliverable_notifications)
    start_and_stop
  end

  it 'enqueues notifications without looping if in push mode' do
    config.stub(:push => true)
    Rpush::Daemon::Feeder.should_not_receive(:feed_forever)
    Rpush::Daemon::Feeder.should_receive(:enqueue_notifications)
    start_and_stop
  end

  it "enqueues the notifications" do
    Rpush::Daemon::AppRunner.should_receive(:enqueue).with([notification])
    start_and_stop
  end

  it "logs errors" do
    e = StandardError.new("bork")
    Rpush::Daemon.store.stub(:deliverable_notifications).and_raise(e)
    Rpush.logger.should_receive(:error).with(e)
    start_and_stop
  end

  describe 'stop' do
    it 'interrupts sleep when stopped' do
      Rpush::Daemon::Feeder.should_receive(:interrupt_sleep)
      start_and_stop
    end

    it 'releases the store connection when stopped' do
      Rpush::Daemon.store.should_receive(:release_connection)
      start_and_stop
    end
  end

  it "enqueues notifications when started" do
    Rpush::Daemon::Feeder.should_receive(:enqueue_notifications).at_least(:once)
    Rpush::Daemon::Feeder.stub(:loop).and_yield
    start_and_stop
  end

  it "sleeps for the given period" do
    config.stub(:push_poll => 2)
    interruptible_sleep.should_receive(:sleep).with(2)
    start_and_stop
  end

  it "creates the wakeup socket" do
    bind = '127.0.0.1'
    port = 12345
    config.stub(:wakeup => { :bind => bind, :port => port})
    interruptible_sleep.should_receive(:enable_wake_on_udp).with(bind, port)
    start_and_stop
  end
end
