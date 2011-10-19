require "spec_helper"

describe Rapns::Daemon::Logger do
  module Rails
    def self.logger
      @logger
    end

    def self.logger=(logger)
      @logger = logger
    end
  end

  module HoptoadNotifier
    def self.notify(e)
    end
  end

  module Airbrake
    def self.notify(e)
    end
  end

  before do
    Rails.stub(:root).and_return("/rails_root")
    @buffered_logger = mock("BufferedLogger", :info => nil, :error => nil, :level => 0, :auto_flushing => 1, :auto_flushing= => nil)
    Rails.logger = @buffered_logger
    ActiveSupport::BufferedLogger.stub(:new).and_return(@buffered_logger)
    configuration = mock("Configuration", :airbrake_notify? => true)
    Rapns::Daemon.stub(:configuration).and_return(configuration)
  end

  it "should open the a log file in the Rails log directory" do
    ActiveSupport::BufferedLogger.should_receive(:new).with("/rails_root/log/rapns.log", Rails.logger.level)
    Rapns::Daemon::Logger.new(:foreground => true)
  end

  it "should print out the msg if running in the foreground" do
    logger = Rapns::Daemon::Logger.new(:foreground => true)
    logger.should_receive(:puts).with(/hi mom/)
    logger.info("hi mom")
  end

  it "should not print out the msg if not running in the foreground" do
    logger = Rapns::Daemon::Logger.new(:foreground => false)
    logger.should_not_receive(:puts).with(/hi mom/)
    logger.info("hi mom")
  end

  it "should prefix log lines with the current time" do
    now = Time.now
    Time.stub(:now).and_return(now)
    logger = Rapns::Daemon::Logger.new(:foreground => false)
    @buffered_logger.should_receive(:info).with(/#{Regexp.escape("[#{now.to_s(:db)}]")}/)
    logger.info("blah")
  end

  it "should prefix error logs with the ERROR label" do
    logger = Rapns::Daemon::Logger.new(:foreground => false)
    @buffered_logger.should_receive(:error).with(/#{Regexp.escape("[ERROR]")}/)
    logger.error("eeek")
  end

  it "should prefix warn logs with the WARNING label" do
    logger = Rapns::Daemon::Logger.new(:foreground => false)
    @buffered_logger.should_receive(:warn).with(/#{Regexp.escape("[WARNING]")}/)
    logger.warn("eeek")
  end

  it "should handle an Exception instance" do
    e = RuntimeError.new("hi mom")
    logger = Rapns::Daemon::Logger.new(:foreground => false)
    @buffered_logger.should_receive(:error).with(/RuntimeError, hi mom/)
    logger.error(e)
  end

  it "should notify Airbrake of the exception" do
    e = RuntimeError.new("hi mom")
    logger = Rapns::Daemon::Logger.new(:foreground => false, :airbrake_notify => true)
    Airbrake.should_receive(:notify).with(e)
    logger.error(e)
  end

  it "should not notify Airbrake of the exception if the airbrake_notify option is false" do
    e = RuntimeError.new("hi mom")
    logger = Rapns::Daemon::Logger.new(:foreground => false, :airbrake_notify => false)
    Airbrake.should_not_receive(:notify).with(e)
    logger.error(e)
  end

  it "should not notify Airbrake if explicitly disabled in the call to error" do
    e = RuntimeError.new("hi mom")
    logger = Rapns::Daemon::Logger.new(:foreground => false, :airbrake_notify => true)
    Airbrake.should_not_receive(:notify).with(e)
    logger.error(e, :airbrake_notify => false)
  end

  it "should not attempt to notify Airbrake of the error is not an Exception" do
    logger = Rapns::Daemon::Logger.new(:foreground => false)
    Airbrake.should_not_receive(:notify)
    logger.error("string error message")
  end

  it 'defaults auto_flushing to true if the Rails logger does not respond to auto_flushing' do
    rails_logger = mock(:info => nil, :error => nil, :level => 0)
    Rails.logger = rails_logger
    logger = Rapns::Daemon::Logger.new({})
    @buffered_logger.auto_flushing.should be_true
  end
end