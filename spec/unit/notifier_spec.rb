require 'spec_helper'
require 'rpush/notifier'

describe Rpush::Notifier do

  before(:each) { @port = 5000 }
  subject { Rpush::Notifier.new('127.0.0.1', @port) }
  its(:socket) { should_not be_nil }

  context "when connected" do
    before :each do
      @reader = UDPSocket.new
      @reader.bind('127.0.0.1', 0)
      @port = @reader.addr[1]
    end

    describe "notify" do
      it "calls write on the socket" do
        UDPSocket.any_instance.should_receive(:write)
        subject.notify
      end

      it "writes data that can be read from socket" do
        subject.notify
        expect(@reader.recv(1)).to eq 'x'
      end
    end
  end

  describe "default notifier" do
    it "creates using :connect first" do
      Rpush.config.stub :wakeup => { :connect => '127.0.0.1', :port => 1234 }
      Rpush::Notifier.should_receive(:new).with('127.0.0.1', 1234)
      Rpush.notifier
    end

    it "creates using :host next" do
      Rpush.config.stub :wakeup => { :host => '127.0.0.1', :port => 1234 }
      Rpush::Notifier.should_receive(:new).with('127.0.0.1', 1234)
      Rpush.notifier
    end

    it "returns nil when wakeup is not specified" do
      Rpush.config.stub :wakeup => nil
      Rpush::Notifier.should_not_receive(:new)
      expect(Rpush.notifier).to be_nil
    end
  end
end
