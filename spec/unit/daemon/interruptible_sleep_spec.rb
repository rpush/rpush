require "unit_spec_helper"

describe Rapns::Daemon::InterruptibleSleep do

  let(:rd) { double(:close => nil) }
  let(:wr) { double(:close => nil) }

  subject { Rapns::Daemon::InterruptibleSleep.new }

  it 'creates a new pipe' do
    IO.should_receive(:pipe)
    subject
  end

  it 'selects on the reader' do
    IO.stub(:pipe => [rd, wr])
    IO.should_receive(:select).with([rd], nil, nil, 1)
    subject.sleep(1)
  end

  it 'closes the writer' do
    IO.stub(:pipe => [rd, wr])
    rd.should_receive(:close)
    wr.should_receive(:close)
    subject.close
  end

  it 'returns false when timeout occurs' do
    expect(subject.sleep(0.01)).to be_false
  end

  it 'returns true when sleep does not timeout' do
    subject.interrupt_sleep
    expect(subject.sleep(0.01)).to be_true
  end

  context 'with UDP socket connected' do
    before :each do
      @host, @port = subject.enable_wake_on_udp('127.0.0.1', 0)
    end

    it 'times out with no udp activity' do
      expect(subject.sleep(0.01)).to be_false
    end

    unless defined? JRUBY_VERSION
      it 'wakes on UDPSocket' do
        waker = UDPSocket.new
        waker.connect(@host, @port)
        waker.write('x')
        expect(subject.sleep(0.01)).to be_true
      end

      it 'consumes all data on udp socket' do
        waker = UDPSocket.new
        waker.connect(@host, @port)
        waker.sendmsg('x')
        waker.sendmsg('x')
        waker.sendmsg('x')
        # true since there is data to be read => no timeout
        expect(subject.sleep(0.01)).to be_true
        # false since data is consumed => wait for full timeout
        expect(subject.sleep(0.01)).to be_false
      end
    end
  end

end
