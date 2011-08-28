require "spec_helper"

describe Rapns::Daemon::Runner do
  before do
    Rapns::Daemon::Runner.stub(:sleep)
    @notification = Rapns::Notification.create!(:device_token => "a" * 64)
    @logger = mock("Logger", :info => nil, :error => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
    @connection_pool = Rapns::Daemon::ConnectionPool.new
    Rapns::Daemon.stub(:connection_pool).and_return(@connection_pool)
    @connection_pool.stub(:write)
    @now = Time.now
    Time.stub(:now).and_return(@now)
  end

  it "should only attempt to deliver undelivered notificatons" do
    @connection_pool.should_receive(:write)
    Rapns::Daemon::Runner.deliver_notifications(:poll => 1)
    @notification.update_attributes(:delivered => true, :delivered_at => Time.now)
    @connection_pool.should_not_receive(:write)
    Rapns::Daemon::Runner.deliver_notifications(:poll => 1)
  end

  it "should send the binary version of the notification" do
    Rapns::Notification.stub(:undelivered).and_return([@notification])
    @notification.stub((:to_binary)).and_return("hi mom")
    @connection_pool.should_receive(:write).with("hi mom")
    Rapns::Daemon::Runner.deliver_notifications(:poll => 1)
  end

  it "should mark the notification as delivered" do
    expect { Rapns::Daemon::Runner.deliver_notifications(:poll => 1); @notification.reload }.to change(@notification, :delivered).to(true)
  end

  it "should set the time the notification was delivered" do
    @notification.delivered_at.should be_nil
    Rapns::Daemon::Runner.deliver_notifications(:poll => 1)
    @notification.reload
    @notification.delivered_at.should be_kind_of(Time)
  end

  it "should not trigger validations when saving the notification" do
    Rapns::Notification.stub(:undelivered).and_return([@notification])
    @notification.should_receive(:save).with(:validate => false)
    Rapns::Daemon::Runner.deliver_notifications(:poll => 1)
  end

  it "should sleep for the given period" do
    Rapns::Daemon::Runner.should_receive(:sleep).with(1)
    Rapns::Daemon::Runner.deliver_notifications(:poll => 1)
  end

  it "should log errors" do
    e = Exception.new("bork")
    @connection_pool.stub(:write).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    Rapns::Daemon::Runner.deliver_notifications(:poll => 1)
  end

  it "should log the notification delivery" do
    Rapns::Daemon.logger.should_receive(:info).with("Notification #{@notification.id} delivered to #{@notification.device_token}")
    Rapns::Daemon::Runner.deliver_notifications(:poll => 1)
  end
end