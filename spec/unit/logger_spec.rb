require "unit_spec_helper"

module Rails
  attr_accessor :logger
end

describe Rpush::Logger do
  let(:log) { double(:sync= => true) }

  before do
    @logger_class = defined?(ActiveSupport::BufferedLogger) ? ActiveSupport::BufferedLogger : ActiveSupport::Logger
    @logger = double(@logger_class.name, info: nil, error: nil, level: 0, auto_flushing: 1, :auto_flushing= => nil)
    @logger_class.stub(:new).and_return(@logger)
    Rails.stub(logger: @logger)
    File.stub(open: log)
    FileUtils.stub(mkdir_p: nil)
    STDERR.stub(:puts)
    Rpush.config.foreground = true
    Rpush.config.log_file = 'log/rpush.log'
  end

  it "disables logging if the log file cannot be opened" do
    File.stub(:open).and_raise(Errno::ENOENT)
    STDERR.should_receive(:puts).with(/No such file or directory/)
    STDERR.should_receive(:puts).with(/Logging disabled/)
    Rpush::Logger.new
  end

  it 'creates the log directory' do
    FileUtils.should_receive(:mkdir_p).with('/tmp/rails_root/log')
    Rpush::Logger.new
  end

  it "should open the a log file in the Rails log directory" do
    File.should_receive(:open).with('/tmp/rails_root/log/rpush.log', 'a')
    Rpush::Logger.new
  end

  it 'sets sync mode on the log descriptor' do
    log.should_receive(:sync=).with(true)
    Rpush::Logger.new
  end

  it 'uses the user-defined logger' do
    my_logger = double
    Rpush.config.logger = my_logger
    logger = Rpush::Logger.new
    my_logger.should_receive(:info)
    Rpush.config.foreground = false
    logger.info('test')
  end

  it 'uses ActiveSupport::BufferedLogger if a user-defined logger is not set' do
    if ActiveSupport.const_defined?('BufferedLogger')
      ActiveSupport::BufferedLogger.should_receive(:new).with(log, Rails.logger.level)
      Rpush::Logger.new
    end
  end

  it 'uses ActiveSupport::Logger if BufferedLogger does not exist' do
    stub_const('ActiveSupport::Logger', double)
    ActiveSupport.stub(:const_defined? => false)
    ActiveSupport::Logger.should_receive(:new).with(log, Rails.logger.level)
    Rpush::Logger.new
  end

  it "should print out the msg if running in the foreground" do
    logger = Rpush::Logger.new
    STDOUT.should_receive(:puts).with(/hi mom/)
    logger.info("hi mom")
  end

  unless Rpush.jruby? # These tests do not work on JRuby.
    it "should not print out the msg if not running in the foreground" do
      Rpush.config.foreground = false
      logger = Rpush::Logger.new
      STDOUT.should_not_receive(:puts).with(/hi mom/)
      logger.info("hi mom")
    end
  end

  it "should prefix log lines with the current time" do
    Rpush.config.foreground = false
    now = Time.now
    Time.stub(:now).and_return(now)
    logger = Rpush::Logger.new
    @logger.should_receive(:info).with(/#{Regexp.escape("[#{now.to_s(:db)}]")}/)
    logger.info("blah")
  end

  it "should prefix error logs with the ERROR label" do
    Rpush.config.foreground = false
    logger = Rpush::Logger.new
    @logger.should_receive(:error).with(/#{Regexp.escape("[ERROR]")}/)
    logger.error("eeek")
  end

  it "should prefix warn logs with the WARNING label" do
    Rpush.config.foreground = false
    logger = Rpush::Logger.new
    @logger.should_receive(:warn).with(/#{Regexp.escape("[WARNING]")}/)
    logger.warn("eeek")
  end

  it "should handle an Exception instance" do
    Rpush.config.foreground = false
    e = RuntimeError.new("hi mom")
    e.stub(backtrace: [])
    logger = Rpush::Logger.new
    @logger.should_receive(:error).with(/RuntimeError, hi mom/)
    logger.error(e)
  end

  it 'defaults auto_flushing to true if the Rails logger does not respond to auto_flushing' do
    Rails.stub(logger: double(info: nil, error: nil, level: 0))
    Rpush::Logger.new
    @logger.auto_flushing.should be_true
  end
end
