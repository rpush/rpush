require "unit_spec_helper"

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

describe Rapns::Daemon::Logger do
  let(:log) { stub(:sync= => true) }
  let(:config) { stub(:airbrake_notify => true) }

  before do
    Rails.stub(:root).and_return("/rails_root")
    @buffered_logger = mock("BufferedLogger", :info => nil, :error => nil, :level => 0, :auto_flushing => 1, :auto_flushing= => nil)
    Rails.logger = @buffered_logger
    ActiveSupport::BufferedLogger.stub(:new).and_return(@buffered_logger)
    Rapns::Daemon.stub(:config => config)
    File.stub(:open => log)
    STDERR.stub(:puts)
  end

  it "disables logging if the log file cannot be opened" do
    File.stub(:open).and_raise(Errno::ENOENT)
    STDERR.should_receive(:puts).with(/No such file or directory/)
    STDERR.should_receive(:puts).with(/Logging disabled/)
    Rapns::Daemon::Logger.new(:foreground => true)
  end

  it "should open the a log file in the Rails log directory" do
    File.should_receive(:open).with('/rails_root/log/rapns.log', 'a')
    Rapns::Daemon::Logger.new(:foreground => true)
  end

  it 'sets sync mode on the log descriptor' do
    log.should_receive(:sync=).with(true)
    Rapns::Daemon::Logger.new(:foreground => true)
  end

  it 'instantiates the BufferedLogger' do
    ActiveSupport::BufferedLogger.should_receive(:new).with(log, Rails.logger.level)
    Rapns::Daemon::Logger.new(:foreground => true)
  end

  it "should print out the msg if running in the foreground" do
    logger = Rapns::Daemon::Logger.new(:foreground => true)
    STDOUT.should_receive(:puts).with(/hi mom/)
    logger.info("hi mom")
  end

  it "should not print out the msg if not running in the foreground" do
    logger = Rapns::Daemon::Logger.new(:foreground => false)
    STDOUT.should_not_receive(:puts).with(/hi mom/)
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
    e.stub(:backtrace => [])
    logger = Rapns::Daemon::Logger.new(:foreground => false)
    @buffered_logger.should_receive(:error).with(/RuntimeError, hi mom/)
    logger.error(e)
  end

  it "should notify Airbrake of the exception" do
    e = RuntimeError.new("hi mom")
    e.stub(:backtrace => [])
    logger = Rapns::Daemon::Logger.new(:foreground => false, :airbrake_notify => true)
    Airbrake.should_receive(:notify_or_ignore).with(e)
    logger.error(e)
  end

  context "without Airbrake defined" do
    before do
      Object.send(:remove_const, :Airbrake)
    end

    after do
      module Airbrake
        def self.notify(e)
        end
      end
    end

    it "should notify using HoptoadNotifier" do
      e = RuntimeError.new("hi mom")
      e.stub(:backtrace => [])
      logger = Rapns::Daemon::Logger.new(:foreground => false, :airbrake_notify => true)
      HoptoadNotifier.should_receive(:notify_or_ignore).with(e)
      logger.error(e)
    end
  end

  it "should not notify Airbrake of the exception if the airbrake_notify option is false" do
    e = RuntimeError.new("hi mom")
    e.stub(:backtrace => [])
    logger = Rapns::Daemon::Logger.new(:foreground => false, :airbrake_notify => false)
    Airbrake.should_not_receive(:notify_or_ignore).with(e)
    logger.error(e)
  end

  it "should not notify Airbrake if explicitly disabled in the call to error" do
    e = RuntimeError.new("hi mom")
    e.stub(:backtrace => [])
    logger = Rapns::Daemon::Logger.new(:foreground => false, :airbrake_notify => true)
    Airbrake.should_not_receive(:notify_or_ignore).with(e)
    logger.error(e, :airbrake_notify => false)
  end

  it "should not attempt to notify Airbrake of the error is not an Exception" do
    logger = Rapns::Daemon::Logger.new(:foreground => false)
    Airbrake.should_not_receive(:notify_or_ignore)
    logger.error("string error message")
  end

  it 'defaults auto_flushing to true if the Rails logger does not respond to auto_flushing' do
    rails_logger = mock(:info => nil, :error => nil, :level => 0)
    Rails.logger = rails_logger
    logger = Rapns::Daemon::Logger.new({})
    @buffered_logger.auto_flushing.should be_true
  end
end
