require "spec_helper"

describe Rapns::Daemon::ConnectionPool do
  before do
    Rapns::Daemon::Connection.stub(:new).and_return(mock("Connection", :connect => nil))
    @pool = Rapns::Daemon::ConnectionPool.new(3)
  end

  it "should populate the pool" do
    Rapns::Daemon::Connection.should_receive(:new).exactly(3).times
    @pool.populate
  end

  it "should tell each connection to close when drained" do
    pool = 3.times.map { mock("Connection") }
    @pool.instance_variable_set("@pool", pool)
    pool.each { |conn| conn.should_receive(:close) }
    @pool.drain
  end

  it "should push the msg into the queue" do
    queue = @pool.instance_variable_get("@queue")
    queue.should_receive(:push).with("blah")
    @pool.write("blah")
  end
end

