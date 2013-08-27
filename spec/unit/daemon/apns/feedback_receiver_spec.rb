require "unit_spec_helper"

describe Rapns::Daemon::Apns::FeedbackReceiver, 'check_for_feedback' do
  let(:host) { 'feedback.push.apple.com' }
  let(:port) { 2196 }
  let(:poll) { 60 }
  let(:certificate) { double }
  let(:password) { double }
  let(:app) { double(:name => 'my_app', :password => password, :certificate => certificate, :environment => 'production') }
  let(:connection) { double(:connect => nil, :read => nil, :close => nil) }
  let(:logger) { double(:error => nil, :info => nil) }
  let(:receiver) { Rapns::Daemon::Apns::FeedbackReceiver.new(app, poll) }
  let(:feedback) { double }

  before do
    receiver.stub(:interruptible_sleep)
    Rapns.stub(:logger => logger)
    Rapns::Daemon::Apns::Connection.stub(:new => connection)
    receiver.instance_variable_set("@stop", false)
    Rapns::Daemon.stub(:store => double(:create_apns_feedback => feedback))
  end

  def double_connection_read_with_tuple
    connection.unstub(:read)

    def connection.read(bytes)
      if !@called
        @called = true
        "N\xE3\x84\r\x00 \x83OxfU\xEB\x9F\x84aJ\x05\xAD}\x00\xAF1\xE5\xCF\xE9:\xC3\xEA\a\x8F\x1D\xA4M*N\xB0\xCE\x17"
      end
    end
  end

  it 'instantiates a new connection' do
    Rapns::Daemon::Apns::Connection.should_receive(:new).with(app, host, port)
    receiver.check_for_feedback
  end

  it 'connects to the feeback service' do
    connection.should_receive(:connect)
    receiver.check_for_feedback
  end

  it 'closes the connection' do
    connection.should_receive(:close)
    receiver.check_for_feedback
  end

  it 'reads from the connection' do
    connection.should_receive(:read).with(38)
    receiver.check_for_feedback
  end

  it 'logs the feedback' do
    double_connection_read_with_tuple
    Rapns.logger.should_receive(:info).with("[my_app] [FeedbackReceiver] Delivery failed at 2011-12-10 16:08:45 UTC for 834f786655eb9f84614a05ad7d00af31e5cfe93ac3ea078f1da44d2a4eb0ce17.")
    receiver.check_for_feedback
  end

  it 'creates the feedback' do
    Rapns::Daemon.store.should_receive(:create_apns_feedback).with(Time.at(1323533325), '834f786655eb9f84614a05ad7d00af31e5cfe93ac3ea078f1da44d2a4eb0ce17', app)
    double_connection_read_with_tuple
    receiver.check_for_feedback
  end

  it 'logs errors' do
    error = StandardError.new('bork!')
    connection.stub(:read).and_raise(error)
    Rapns.logger.should_receive(:error).with(error)
    receiver.check_for_feedback
  end

  it 'sleeps for the feedback poll period' do
    receiver.stub(:check_for_feedback)
    receiver.should_receive(:interruptible_sleep).with(60).at_least(:once)
    Thread.stub(:new).and_yield
    receiver.stub(:loop).and_yield
    receiver.start
  end

  it 'checks for feedback when started' do
    receiver.should_receive(:check_for_feedback).at_least(:once)
    Thread.stub(:new).and_yield
    receiver.stub(:loop).and_yield
    receiver.start
  end

  it 'interrupts sleep when stopped' do
    receiver.stub(:check_for_feedback)
    receiver.should_receive(:interrupt_sleep)
    receiver.stop
  end

  it 'reflects feedback was received' do
    double_connection_read_with_tuple
    receiver.should_receive(:reflect).with(:apns_feedback, feedback)
    receiver.check_for_feedback
  end

  it 'calls the apns_feedback_callback when feedback is received and the callback is set' do
    double_connection_read_with_tuple
    Rapns.config.apns_feedback_callback = Proc.new {}
    Rapns.config.apns_feedback_callback.should_receive(:call).with(feedback)
    receiver.check_for_feedback
  end

  it 'catches exceptions in the apns_feedback_callback' do
    error = StandardError.new('bork!')
    double_connection_read_with_tuple
    callback = Proc.new { raise error }
    Rapns::Deprecation.muted do
      Rapns.config.on_apns_feedback &callback
    end
    expect { receiver.check_for_feedback }.not_to raise_error
  end

  it 'logs an exception from the apns_feedback_callback' do
    error = StandardError.new('bork!')
    double_connection_read_with_tuple
    callback = Proc.new { raise error }
    Rapns.logger.should_receive(:error).with(error)
    Rapns::Deprecation.muted do
      Rapns.config.on_apns_feedback &callback
    end
    receiver.check_for_feedback
  end
end
