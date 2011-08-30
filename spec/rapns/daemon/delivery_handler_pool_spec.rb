require "spec_helper"

describe Rapns::Daemon::DeliveryHandlerPool do
  before do
    @handler = mock("DeliveryHandler", :start => nil)
    Rapns::Daemon::DeliveryHandler.stub(:new).and_return(@handler)
    @pool = Rapns::Daemon::DeliveryHandlerPool.new(3)
    Rapns::Daemon.stub(:delivery_queue).and_return(mock("Delivery queue", :push => nil))
  end

  it "should populate the pool" do
    Rapns::Daemon::DeliveryHandler.should_receive(:new).exactly(3).times
    @pool.populate
  end

  it "should tell each connection to close when drained" do
    @pool.populate
    @handler.should_receive(:stop).exactly(3).times
    @pool.drain
  end

  it "should initiate the topping process for each DeliveryHandler before the pool is drained" do
    Rapns::Daemon.delivery_queue.should_receive(:push).with(0x666).exactly(3).times
    @pool.drain
  end
end