require "spec_helper"

describe Rapns::Daemon::ConnectionPool do
  before do
    @connection = mock("Connection", :connect => nil)
    Rapns::Daemon::Connection.stub(:new).and_return(@connection)
    @pool = Rapns::Daemon::ConnectionPool.new(3)
  end

  it "should populate the pool" do
    Rapns::Daemon::Connection.should_receive(:new).exactly(3).times
    @pool.populate
  end

  it "should tell each connection to close when drained" do
    @pool.populate
    @connection.should_receive(:close).exactly(3).times
    @pool.drain
  end
end

describe Rapns::Daemon::ConnectionPool, "when claiming a connection" do
  before do
    @connection = mock("Connection", :connect => nil)
    Rapns::Daemon::Connection.stub(:new).and_return(@connection)
    @pool = Rapns::Daemon::ConnectionPool.new(3)
  end

  it "should pop the connection from the pool" do
    @pool.instance_variable_get("@queue").should_receive(:pop)
    @pool.claim_connection {}
  end

  it "shuld push the connection into the pool after use" do
    @pool.instance_variable_get("@queue").stub(:pop).and_return(@connection)
    @pool.instance_variable_get("@queue").should_receive(:push).with(@connection)
    @pool.claim_connection {}
  end
end

