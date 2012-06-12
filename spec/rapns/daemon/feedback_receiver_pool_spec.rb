require "spec_helper"

describe Rapns::Daemon::FeedbackReceiverPool do
  let(:pool) { Rapns::Daemon::FeedbackReceiverPool.new }
  let(:receiver) { stub(:start => nil, :stop => nil) }
  
  it 'starts the receiver when added to the pool' do
    receiver.should_receive(:start)
    pool << receiver
  end

  it 'stops each receiver when drained' do
    pool << receiver
    receiver.should_receive(:stop)
    pool.drain
  end
end