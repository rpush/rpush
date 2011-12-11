
describe Rapns::Daemon::InterruptibleSleep do
  class SleepTest
    extend Rapns::Daemon::InterruptibleSleep
  end

  before do
    IO.stub(:pipe)
    IO.stub(:select)
  end

  it 'creates a new pipe' do
    IO.should_receive(:pipe)
    SleepTest.interruptible_sleep 1
  end

  it 'selects on the reader' do
    rd = stub
    IO.stub(:pipe => [rd, stub])
    IO.should_receive(:select).with([rd], nil, nil, 1)
    SleepTest.interruptible_sleep 1
  end

  it 'closes the writer' do
    wr = stub
    IO.stub(:pipe => [stub, wr])
    SleepTest.interruptible_sleep 1
    wr.should_receive(:close)
    SleepTest.interrupt_sleep
  end
end