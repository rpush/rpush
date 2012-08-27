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

  before do
    Rapns::Daemon.stub(:delivery_queues => delivery_queues, :logger => logger, :config => config)
    delivery_handler.queue = queue
    queue.push(notification)
  end
end