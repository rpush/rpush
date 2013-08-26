require 'unit_spec_helper'

describe Rapns::Daemon::DeliveryHandlerCollection do
  let(:handler) { double.as_null_object }
  let(:collection) { Rapns::Daemon::DeliveryHandlerCollection.new }

  it 'returns the size of the collection' do
    collection.push(handler)
    collection.size.should eq 1
  end

  it 'pops a handler from the collection' do
    collection.push(handler)
    handler.should_receive(:stop)
    handler.should_receive(:wakeup)
    handler.should_receive(:wait)
    collection.pop
    collection.size.should eq 0
  end

  it 'wakes up all handlers when popping a single handler' do
    collection.push(handler)
    handler2 = double.as_null_object
    collection.push(handler2)
    handler.should_receive(:wakeup)
    handler2.should_receive(:wakeup)
    collection.pop
  end

  it 'stops all handlers' do
    collection.push(handler)
    handler.should_receive(:stop)
    handler.should_receive(:wakeup)
    handler.should_receive(:wait)
    collection.stop
  end
end
