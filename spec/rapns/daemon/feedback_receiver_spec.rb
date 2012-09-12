require "spec_helper"

describe Rapns::Daemon::FeedbackReceiver, 'check_for_feedback' do
  let(:host) { 'feedback.push.apple.com' }
  let(:port) { 2196 }
  let(:poll) { 60 }
  let(:certificate) { stub }
  let(:password) { stub }
  let(:app) { 'my_app' }
  let(:connection) { stub(:connect => nil, :read => nil, :close => nil) }
  let(:logger) { stub(:error => nil, :info => nil) }
  let(:receiever) { Rapns::Daemon::FeedbackReceiver.new(app, host, port, poll, certificate, password) }

  before do
    receiever.stub(:interruptible_sleep)
    Rapns::Daemon.logger = logger
    Rapns::Daemon::Connection.stub(:new => connection)
    Rapns::Feedback.stub(:create!)
    receiever.instance_variable_set("@stop", false)
  end

  def stub_connection_read_with_tuple
    connection.unstub(:read)

    def connection.read(bytes)
      if !@called
        @called = true
        "N\xE3\x84\r\x00 \x83OxfU\xEB\x9F\x84aJ\x05\xAD}\x00\xAF1\xE5\xCF\xE9:\xC3\xEA\a\x8F\x1D\xA4M*N\xB0\xCE\x17"
      end
    end
  end

  it 'instantiates a new connection' do  
    Rapns::Daemon::Connection.should_receive(:new).with("FeedbackReceiver:#{app}", host, port, certificate, password)
    receiever.check_for_feedback
  end

  it 'connects to the feeback service' do
    connection.should_receive(:connect)
    receiever.check_for_feedback
  end

  it 'closes the connection' do
    connection.should_receive(:close)
    receiever.check_for_feedback
  end

  it 'reads from the connection' do
    connection.should_receive(:read).with(38)
    receiever.check_for_feedback
  end

  it 'logs the feedback' do
    stub_connection_read_with_tuple
    Rapns::Daemon.logger.should_receive(:info).with("[FeedbackReceiver:my_app] Delivery failed at 2011-12-10 16:08:45 UTC for 834f786655eb9f84614a05ad7d00af31e5cfe93ac3ea078f1da44d2a4eb0ce17")
    receiever.check_for_feedback
  end

  it 'creates the feedback' do
    stub_connection_read_with_tuple
    Rapns::Feedback.should_receive(:create!).with(:failed_at => Time.at(1323533325), :device_token => '834f786655eb9f84614a05ad7d00af31e5cfe93ac3ea078f1da44d2a4eb0ce17', :app => 'my_app')
    receiever.check_for_feedback
  end

  it 'logs errors' do
    error = StandardError.new('bork!')
    connection.stub(:read).and_raise(error)
    Rapns::Daemon.logger.should_receive(:error).with(error)
    lambda { receiever.check_for_feedback }.should raise_error
  end

  it 'sleeps for the feedback poll period' do
    receiever.stub(:check_for_feedback)
    receiever.should_receive(:interruptible_sleep).with(60).at_least(:once)
    Thread.stub(:new).and_yield
    receiever.stub(:loop).and_yield
    receiever.start
  end

  it 'checks for feedback when started' do
    receiever.should_receive(:check_for_feedback).at_least(:once)
    Thread.stub(:new).and_yield
    receiever.stub(:loop).and_yield
    receiever.start
  end

  it 'interrupts sleep when stopped' do
    receiever.stub(:check_for_feedback)
    receiever.should_receive(:interrupt_sleep)
    receiever.stop
  end
end