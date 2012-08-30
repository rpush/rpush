require "unit_spec_helper"
require File.dirname(__FILE__) + '/../delivery_handler_shared.rb'

describe Rapns::Daemon::Gcm::DeliveryHandler do
  it_should_behave_like 'an DeliveryHandler sublcass'

  let(:delivery_handler) { Rapns::Daemon::Gcm::DeliveryHandler.new }
  let(:queue) { Rapns::Daemon::DeliveryQueue.new }
  let(:notification) { stub.as_null_object }
  let(:logger) { stub(:error => nil, :info => nil) }
  let(:config) { stub(:check_for_errors => true) }
  let(:delivery_queues) { [] }
  let(:http) { stub(:shutdown => nil)}

  before do
    Net::HTTP::Persistent.stub(:new => http)
    Rapns::Daemon.stub(:delivery_queues => delivery_queues, :logger => logger, :config => config)
    delivery_handler.queue = queue
    queue.push(notification)
  end

  it 'initiates a persistent connection object' do
    Net::HTTP::Persistent.should_receive(:new).with('rapns')
    Rapns::Daemon::Gcm::DeliveryHandler.new
  end

  describe 'when being stopped' do
    it 'shuts down the http connection when a DeliveryQueue::WakeupError is raised' do
      http.should_receive(:shutdown)
      delivery_handler.start
      delivery_handler.stop
    end
  end
end