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

describe Rapns::Logger do
  let(:log) { double(:sync= => true) }

  before do
    Rails.stub(:root).and_return("/rails_root")

    @logger_class = if defined?(ActiveSupport::BufferedLogger)
      ActiveSupport::BufferedLogger
    else
      ActiveSupport::Logger
    end

    @logger = double(@logger_class.name, :info => nil, :error => nil, :level => 0, :auto_flushing => 1, :auto_flushing= => nil)
    @logger_class.stub(:new).and_return(@logger)
    Rails.logger = @logger
    File.stub(:open => log)
    STDERR.stub(:puts)
  end

  it "disables logging if the log file cannot be opened" do
    File.stub(:open).and_raise(Errno::ENOENT)
    STDERR.should_receive(:puts).with(/No such file or directory/)
    STDERR.should_receive(:puts).with(/Logging disabled/)
    Rapns::Logger.new(:foreground => true)
  end

  it "should open the a log file in the Rails log directory" do
    File.should_receive(:open).with('/rails_root/log/rapns.log', 'a')
    Rapns::Logger.new(:foreground => true)
  end

  it 'sets sync mode on the log descriptor' do
    log.should_receive(:sync=).with(true)
    Rapns::Logger.new(:foreground => true)
  end

  it 'uses the user-defined logger' do
    my_logger = double
    Rapns.config.logger = my_logger
    logger = Rapns::Logger.new({})
    my_logger.should_receive(:info)
    logger.info('test')
  end

  it 'uses ActiveSupport::BufferedLogger if a user-defined logger is not set' do
    if ActiveSupport.const_defined?('BufferedLogger')
      ActiveSupport::BufferedLogger.should_receive(:new).with(log, Rails.logger.level)
      Rapns::Logger.new(:foreground => true)
    end
  end

  it 'uses ActiveSupport::Logger if BufferedLogger does not exist' do
    stub_const('ActiveSupport::Logger', double)
    ActiveSupport.stub(:const_defined? => false)
    ActiveSupport::Logger.should_receive(:new).with(log, Rails.logger.level)
    Rapns::Logger.new(:foreground => true)
  end

  it "should print out the msg if running in the foreground" do
    logger = Rapns::Logger.new(:foreground => true)
    STDOUT.should_receive(:puts).with(/hi mom/)
    logger.info("hi mom")
  end

  it "should not print out the msg if not running in the foreground" do
    logger = Rapns::Logger.new(:foreground => false)
    STDOUT.should_not_receive(:puts).with(/hi mom/)
    logger.info("hi mom")
  end

  it "should prefix log lines with the current time" do
    now = Time.now
    Time.stub(:now).and_return(now)
    logger = Rapns::Logger.new(:foreground => false)
    @logger.should_receive(:info).with(/#{Regexp.escape("[#{now.to_s(:db)}]")}/)
    logger.info("blah")
  end

  it "should prefix error logs with the ERROR label" do
    logger = Rapns::Logger.new(:foreground => false)
    @logger.should_receive(:error).with(/#{Regexp.escape("[ERROR]")}/)
    logger.error("eeek")
  end

  it "should prefix warn logs with the WARNING label" do
    logger = Rapns::Logger.new(:foreground => false)
    @logger.should_receive(:warn).with(/#{Regexp.escape("[WARNING]")}/)
    logger.warn("eeek")
  end

  it "should handle an Exception instance" do
    e = RuntimeError.new("hi mom")
    e.stub(:backtrace => [])
    logger = Rapns::Logger.new(:foreground => false)
    @logger.should_receive(:error).with(/RuntimeError, hi mom/)
    logger.error(e)
  end

  it 'defaults auto_flushing to true if the Rails logger does not respond to auto_flushing' do
    rails_logger = double(:info => nil, :error => nil, :level => 0)
    Rails.logger = rails_logger
    @logger.auto_flushing.should be_true
  end
end
