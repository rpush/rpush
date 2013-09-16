require "unit_spec_helper"

describe Rapns::Daemon::Feeder do
  let(:config) { double(:batch_size => 5000,
                        :push_poll => 0,
                        :embedded => false,
                        :push => false,
                        :wakeup => nil) }
  let!(:app) { Rapns::Apns::App.create!(:name => 'my_app', :environment => 'development', :certificate => TEST_CERT) }
  let(:notification) { Rapns::Apns::Notification.create!(:device_token => "a" * 64, :app => app) }
  let(:logger) { double }

  before do
    Rapns.stub(:config => config,:logger => logger)
    Rapns::Daemon.stub(:store => double(:deliverable_notifications => [notification]))
    Rapns::Daemon::Feeder.stub(:stop? => true)
    Rapns::Daemon::AppRunner.stub(:enqueue => nil, :idle => [double(:app => app)])
  end

  def start
    Rapns::Daemon::Feeder.start
  end

  it "starts the loop in a new thread if embedded" do
    config.stub(:embedded => true)
    Thread.should_receive(:new).and_yield
    Rapns::Daemon::Feeder.should_receive(:feed_forever)
    start
  end

  it 'loads deliverable notifications' do
    Rapns::Daemon.store.should_receive(:deliverable_notifications).with([app])
    start
  end

  it 'does not attempt to load deliverable notifications if there are no idle runners' do
    Rapns::Daemon::AppRunner.stub(:idle => [])
    Rapns::Daemon.store.should_not_receive(:deliverable_notifications)
    start
  end

  it 'enqueues notifications without looping if in push mode' do
    config.stub(:push => true)
    Rapns::Daemon::Feeder.should_not_receive(:feed_forever)
    Rapns::Daemon::Feeder.should_receive(:enqueue_notifications)
    start
  end

  it "enqueues the notifications" do
    Rapns::Daemon::AppRunner.should_receive(:enqueue).with([notification])
    start
  end

  it "logs errors" do
    e = StandardError.new("bork")
    Rapns::Daemon.store.stub(:deliverable_notifications).and_raise(e)
    Rapns.logger.should_receive(:error).with(e)
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
    config.stub(:push_poll => 2)
    sleeper = double(:sleep => true)
    sleeper.should_receive(:sleep).with(2)
    Rapns::Daemon::Feeder.stub(:interruptible_sleeper => sleeper)
    Rapns::Daemon::Feeder.stub(:loop).and_yield
    Rapns::Daemon::Feeder.start
  end

  it "creates the wakeup socket" do
    bind = '127.0.0.1'
    port = 12345
    config.stub(:wakeup => { :bind => bind, :port => port})
    sleeper = double(:enable_wake_on_udp => [bind, port])
    sleeper.should_receive(:enable_wake_on_udp).with(bind, port)
    Rapns::Daemon::InterruptibleSleep.stub(:new => sleeper)
    # kludgy, but the instance variable is already set in previous tests, and this test
    # requires it to be *not* initialised from a previous test.
    Rapns::Daemon::Feeder.class_eval <<-EOF
      def self.reset_interruptible_sleeper
        @interruptible_sleeper = nil
      end
    EOF
    Rapns::Daemon::Feeder.reset_interruptible_sleeper
    Rapns::Daemon::Feeder.interruptible_sleeper
  end

end
