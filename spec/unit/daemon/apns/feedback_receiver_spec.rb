require 'unit_spec_helper'
require 'rpush/daemon/store/active_record'

describe Rpush::Daemon::Apns::FeedbackReceiver, 'check_for_feedback' do

  let(:host) { 'feedback.push.apple.com' }
  let(:port) { 2196 }
  let(:poll) { 60 }
  let(:certificate) { double }
  let(:password) { double }
  let(:app) { double(name: 'my_app', password: password, certificate: certificate, environment: 'production') }
  let(:connection) { double(connect: nil, read: nil, close: nil) }
  let(:logger) { double(error: nil, info: nil) }
  let(:receiver) { Rpush::Daemon::Apns::FeedbackReceiver.new(app) }
  let(:feedback) { double }
  let(:sleeper) { double(Rpush::Daemon::InterruptibleSleep, sleep: nil, start: nil, stop: nil) }
  let(:store) { double(Rpush::Daemon::Store::ActiveRecord, create_apns_feedback: feedback, release_connection: nil) }

  before do
    Rpush.config.feedback_poll = poll
    Rpush::Daemon::InterruptibleSleep.stub(new: sleeper)
    Rpush.stub(logger: logger)
    Rpush::Daemon::TcpConnection.stub(new: connection)
    receiver.instance_variable_set("@stop", false)
    Rpush::Daemon.stub(store: store)
  end

  def double_connection_read_with_tuple
    connection.unstub(:read)

    def connection.read(*)
      unless @called
        @called = true
        "N\xE3\x84\r\x00 \x83OxfU\xEB\x9F\x84aJ\x05\xAD}\x00\xAF1\xE5\xCF\xE9:\xC3\xEA\a\x8F\x1D\xA4M*N\xB0\xCE\x17"
      end
    end
  end

  it 'initializes the sleeper with the feedback polling duration' do
    Rpush::Daemon::InterruptibleSleep.should_receive(:new).with(poll).and_return(sleeper)
    Rpush::Daemon::Apns::FeedbackReceiver.new(app)
  end

  it 'instantiates a new connection' do
    Rpush::Daemon::TcpConnection.should_receive(:new).with(app, host, port)
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
    Rpush.logger.should_receive(:info).with("[my_app] [FeedbackReceiver] Delivery failed at 2011-12-10 16:08:45 UTC for 834f786655eb9f84614a05ad7d00af31e5cfe93ac3ea078f1da44d2a4eb0ce17.")
    receiver.check_for_feedback
  end

  it 'creates the feedback' do
    Rpush::Daemon.store.should_receive(:create_apns_feedback).with(Time.at(1_323_533_325), '834f786655eb9f84614a05ad7d00af31e5cfe93ac3ea078f1da44d2a4eb0ce17', app)
    double_connection_read_with_tuple
    receiver.check_for_feedback
  end

  it 'logs errors' do
    error = StandardError.new('bork!')
    connection.stub(:read).and_raise(error)
    Rpush.logger.should_receive(:error).with(error)
    receiver.check_for_feedback
  end

  describe 'start' do
    before do
      Thread.stub(:new).and_yield
      receiver.stub(:loop).and_yield
    end

    it 'sleeps' do
      receiver.stub(:check_for_feedback)
      sleeper.should_receive(:sleep).at_least(:once)
      receiver.start
    end

    it 'checks for feedback when started' do
      receiver.should_receive(:check_for_feedback).at_least(:once)
      receiver.start
    end
  end

  describe 'stop' do
    it 'interrupts sleep when stopped' do
      receiver.stub(:check_for_feedback)
      sleeper.should_receive(:stop)
      receiver.stop
    end

    it 'releases the store connection' do
      Thread.stub(:new).and_yield
      receiver.stub(:loop).and_yield
      Rpush::Daemon.store.should_receive(:release_connection)
      receiver.start
      receiver.stop
    end
  end

  it 'reflects feedback was received' do
    double_connection_read_with_tuple
    receiver.should_receive(:reflect).with(:apns_feedback, feedback)
    receiver.check_for_feedback
  end
end
