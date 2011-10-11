require "spec_helper"

describe Rapns::Daemon::Feeder do
  before do
    Rapns::Daemon::Feeder.stub(:sleep)
    @notification = Rapns::Notification.create!(:device_token => "a" * 64)
    @logger = mock("Logger", :info => nil, :error => nil, :warn => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
    @queue = mock(:push => nil, :wait_for_available_handler => nil)
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

  it "should wait for a delivery handler to become available" do
    Rapns::Daemon.delivery_queue.should_receive(:wait_for_available_handler)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  it "should log errors" do
    e = StandardError.new("bork")
    Rapns::Notification.stub(:ready_for_delivery).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    Rapns::Daemon::Feeder.enqueue_notifications
  end

  context "when the database connection is lost" do
    let(:error) { adapter_error.new("db down!") }
    before do
      ActiveRecord::Base.stub(:clear_all_connections!)
      ActiveRecord::Base.stub(:establish_connection)
      Rapns::Notification.stub(:ready_for_delivery).and_raise(error)
    end

    def adapter_error
      case $adapter
      when 'postgresql'
        PGError
      when 'mysql'
        Mysql::Error
      when 'mysql2'
        Mysql2::Error
      else
        raise "Please update #{__FILE__} for adapter #{$adapter}"
      end
    end

    it "should log the error raised" do
      Rapns::Daemon.logger.should_receive(:error).with(error)
      Rapns::Daemon::Feeder.enqueue_notifications
    end

    it "should log that the database is being reconnected" do
      Rapns::Daemon.logger.should_receive(:warn).with("Lost connection to database, reconnecting...")
      Rapns::Daemon::Feeder.enqueue_notifications
    end

    it "should log the reconnection attempt" do
      Rapns::Daemon.logger.should_receive(:warn).with("Attempt 1")
      Rapns::Daemon::Feeder.enqueue_notifications
    end

    it "should clear all connections" do
      ActiveRecord::Base.should_receive(:clear_all_connections!)
      Rapns::Daemon::Feeder.enqueue_notifications
    end

    it "should establish a new connection" do
      ActiveRecord::Base.should_receive(:establish_connection)
      Rapns::Daemon::Feeder.enqueue_notifications
    end

    it "should test out the new connection by performing a count" do
      Rapns::Notification.should_receive(:count)
      Rapns::Daemon::Feeder.enqueue_notifications
    end

    context "when the reconnection attempt is not successful" do
      let(:error) { adapter_error.new("shit got real") }

      before do
        class << Rapns::Notification
          def count
            @count_calls += 1
            return if @count_calls == 2
            raise @error
          end
        end
        Rapns::Notification.instance_variable_set("@count_calls", 0)
        Rapns::Notification.instance_variable_set("@error", error)
      end

      it "should log errors raised when the reconnection is not successful without notifying airbrake" do
        Rapns::Daemon.logger.should_receive(:error).with(error, :airbrake_notify => false)
        Rapns::Daemon::Feeder.enqueue_notifications
      end

      it "should sleep to avoid thrashing when the database is down" do
        Rapns::Daemon::Feeder.should_receive(:sleep).with(2)
        Rapns::Daemon::Feeder.enqueue_notifications
      end
    end
  end
end