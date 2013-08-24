require 'unit_spec_helper'
require 'rapns/daemon/store/active_record/reconnectable'

describe Rapns::Daemon::Store::ActiveRecord::Reconnectable do
  class TestDouble
    include Rapns::Daemon::Store::ActiveRecord::Reconnectable

    attr_reader :name

    def initialize(error, max_calls)
      @error = error
      @max_calls = max_calls
      @calls = 0
    end

    def perform
      with_database_reconnect_and_retry do
        @calls += 1
        raise @error if @calls <= @max_calls
      end
    end
  end

  let(:adapter_error_class) do
    case $adapter
    when 'postgresql'
      PGError
    when 'mysql'
      Mysql::Error
    when 'mysql2'
      Mysql2::Error
    when 'jdbcpostgresql'
      ActiveRecord::JDBCError
    when 'jdbcmysql'
      ActiveRecord::JDBCError
    when 'jdbch2'
      ActiveRecord::JDBCError
    else
      raise "Please update #{__FILE__} for adapter #{$adapter}"
    end
  end
  let(:error) { adapter_error_class.new("db down!") }
  let(:test_double) { TestDouble.new(error, 1) }

  before do
    @logger = double("Logger", :info => nil, :error => nil, :warn => nil)
    Rapns.stub(:logger).and_return(@logger)

    ActiveRecord::Base.stub(:clear_all_connections!)
    ActiveRecord::Base.stub(:establish_connection)
    test_double.stub(:sleep)
  end

  it "should log the error raised" do
    Rapns.logger.should_receive(:error).with(error)
    test_double.perform
  end

  it "should log that the database is being reconnected" do
    Rapns.logger.should_receive(:warn).with("Lost connection to database, reconnecting...")
    test_double.perform
  end

  it "should log the reconnection attempt" do
    Rapns.logger.should_receive(:warn).with("Attempt 1")
    test_double.perform
  end

  it "should clear all connections" do
    ActiveRecord::Base.should_receive(:clear_all_connections!)
    test_double.perform
  end

  it "should establish a new connection" do
    ActiveRecord::Base.should_receive(:establish_connection)
    test_double.perform
  end

  it "should test out the new connection by performing a count" do
    Rapns::Notification.should_receive(:count)
    test_double.perform
  end

  context "when the reconnection attempt is not successful" do
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

    it "should log the 2nd attempt" do
      Rapns.logger.should_receive(:warn).with("Attempt 2")
      test_double.perform
    end

    it "should log errors raised when the reconnection is not successful without notifying airbrake" do
      Rapns.logger.should_receive(:error).with(error, :airbrake_notify => false)
      test_double.perform
    end

    it "should sleep to avoid thrashing when the database is down" do
      test_double.should_receive(:sleep).with(2)
      test_double.perform
    end
  end
end
