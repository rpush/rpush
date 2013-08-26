require "unit_spec_helper"
require File.dirname(__FILE__) + '/../delivery_handler_shared.rb'

describe Rapns::Daemon::Gcm::DeliveryHandler do
  it_should_behave_like 'an DeliveryHandler subclass'

  let(:notification) { double }
  let(:batch) { double(:notification_processed => nil) }
  let(:queue) { Queue.new }
  let(:app) { double }
  let(:delivery_handler) { Rapns::Daemon::Gcm::DeliveryHandler.new(app) }
  let(:http) { double(:shutdown => nil) }
  let(:delivery) { double(:perform => nil) }

  before do
    Net::HTTP::Persistent.stub(:new => http)
    Rapns::Daemon::Gcm::Delivery.stub(:new => delivery)
    delivery_handler.queue = queue
    queue.push([notification, batch])
  end

  def run_delivery_handler
    delivery_handler.start
    delivery_handler.stop
    delivery_handler.wakeup
    delivery_handler.wait
  end

  it 'performs delivery of an notification' do
    Rapns::Daemon::Gcm::Delivery.should_receive(:new).with(app, http, notification, batch).and_return(delivery)
    delivery.should_receive(:perform)
    run_delivery_handler
  end

  it 'initiates a persistent connection object' do
    Net::HTTP::Persistent.should_receive(:new).with('rapns')
    Rapns::Daemon::Gcm::DeliveryHandler.new(app)
  end

  it 'shuts down the http connection stopped' do
    http.should_receive(:shutdown)
    run_delivery_handler
  end
end
