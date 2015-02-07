require 'unit_spec_helper'
require 'rpush/daemon/store/active_record/reconnectable'

describe Rpush::Daemon::Store::ActiveRecord::Reconnectable do
  class TestDouble
    include Rpush::Daemon::Store::ActiveRecord::Reconnectable

    attr_reader :name

    def initialize(error, max_calls)
      @error = error
      @max_calls = max_calls
      @calls = 0
    end

    def perform
      with_database_reconnect_and_retry do
        @calls += 1
        fail @error if @calls <= @max_calls
      end
    end
  end

  let(:adapter_error_class) do
    case SPEC_ADAPTER
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
    when 'sqlite3'
      SQLite3::Exception
    else
      fail "Please update #{__FILE__} for adapter #{SPEC_ADAPTER}"
    end
  end

  let(:error) { adapter_error_class.new("db down!") }
  let(:timeout) { ActiveRecord::ConnectionTimeoutError.new("db lazy!") }
  let(:test_doubles) { [TestDouble.new(error, 1), TestDouble.new(timeout, 1)]  }

  before do
    @logger = double("Logger", info: nil, error: nil, warn: nil)
    allow(Rpush).to receive(:logger).and_return(@logger)

    allow(ActiveRecord::Base).to receive(:clear_all_connections!)
    allow(ActiveRecord::Base).to receive(:establish_connection)
    test_doubles.each { |td| allow(td).to receive(:sleep) }
  end

  it "should log the error raised" do
    expect(Rpush.logger).to receive(:error).with(error)
    test_doubles.each(&:perform)
  end

  it "should log that the database is being reconnected" do
    expect(Rpush.logger).to receive(:warn).with("Lost connection to database, reconnecting...")
    test_doubles.each(&:perform)
  end

  it "should log the reconnection attempt" do
    expect(Rpush.logger).to receive(:warn).with("Attempt 1")
    test_doubles.each(&:perform)
  end

  it "should clear all connections" do
    expect(ActiveRecord::Base).to receive(:clear_all_connections!)
    test_doubles.each(&:perform)
  end

  it "should establish a new connection" do
    expect(ActiveRecord::Base).to receive(:establish_connection)
    test_doubles.each(&:perform)
  end

  it "should test out the new connection by performing a count" do
    expect(Rpush::Client::ActiveRecord::Notification).to receive(:count).twice
    test_doubles.each(&:perform)
  end

  context "when the reconnection attempt is not successful" do
    before do
      class << Rpush::Client::ActiveRecord::Notification
        def count
          @count_calls += 1
          return if @count_calls == 2
          fail @error
        end
      end
      Rpush::Client::ActiveRecord::Notification.instance_variable_set("@count_calls", 0)
      Rpush::Client::ActiveRecord::Notification.instance_variable_set("@error", error)
    end

    describe "error behaviour" do
      it "should log the 2nd attempt" do
        expect(Rpush.logger).to receive(:warn).with("Attempt 2")
        test_doubles[0].perform
      end

      it "should log errors raised when the reconnection is not successful" do
        expect(Rpush.logger).to receive(:error).with(error)
        test_doubles[0].perform
      end

      it "should sleep to avoid thrashing when the database is down" do
        expect(test_doubles[0]).to receive(:sleep).with(2)
        test_doubles[0].perform
      end
    end

    describe "timeout behaviour" do
      it "should log the 2nd attempt" do
        expect(Rpush.logger).to receive(:warn).with("Attempt 2")
        test_doubles[1].perform
      end

      it "should log errors raised when the reconnection is not successful" do
        expect(Rpush.logger).to receive(:error).with(error)
        test_doubles[1].perform
      end

      it "should sleep to avoid thrashing when the database is down" do
        expect(test_doubles[1]).to receive(:sleep).with(2)
        test_doubles[1].perform
      end
    end
  end
end if active_record?
