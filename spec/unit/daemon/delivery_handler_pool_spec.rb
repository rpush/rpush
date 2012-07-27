require "unit_spec_helper"

describe Rapns::Daemon::DeliveryHandlerPool do
  let(:pool) { Rapns::Daemon::DeliveryHandlerPool.new }
  let(:handler) { stub(:start => nil, :stop => nil) }

  it 'starts the handler when added to the pool' do
    handler.should_receive(:start)
    pool << handler
  end

  it 'stops each handler when drained' do
    pool << handler
    handler.should_receive(:stop)
    pool.drain
  end
end