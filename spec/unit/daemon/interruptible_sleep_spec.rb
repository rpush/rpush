require "unit_spec_helper"

describe Rapns::Daemon::InterruptibleSleep do
  class SleepTest
    extend Rapns::Daemon::InterruptibleSleep
  end

  let(:rd) { double(:close => nil) }
  let(:wr) { double(:close => nil) }

  before do
    IO.stub(:pipe)
    IO.stub(:select)
  end

  it 'creates a new pipe' do
    IO.should_receive(:pipe)
    SleepTest.interruptible_sleep 1
  end

  it 'selects on the reader' do
    IO.stub(:pipe => [rd, wr])
    IO.should_receive(:select).with([rd], nil, nil, 1)
    SleepTest.interruptible_sleep 1
  end

  it 'closes both ends of the pipe after the timeout' do
    IO.stub(:pipe => [rd, wr])
    rd.should_receive(:close)
    wr.should_receive(:close)
    SleepTest.interruptible_sleep 1
  end

  it 'closes the writer' do
    IO.stub(:pipe => [rd, wr])
    SleepTest.interruptible_sleep 1
    wr.should_receive(:close)
    SleepTest.interrupt_sleep
  end
end
