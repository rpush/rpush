require 'unit_spec_helper'

describe Rapns::Daemon::DispatcherLoopCollection do
  let(:dispatcher_loop) { double.as_null_object }
  let(:collection) { Rapns::Daemon::DispatcherLoopCollection.new }

  it 'returns the size of the collection' do
    collection.push(dispatcher_loop)
    collection.size.should eq 1
  end

  it 'pops a dispatcher loop from the collection' do
    collection.push(dispatcher_loop)
    dispatcher_loop.should_receive(:stop)
    dispatcher_loop.should_receive(:wakeup)
    dispatcher_loop.should_receive(:wait)
    collection.pop
    collection.size.should eq 0
  end

  it 'wakes up all dispatcher loops when popping a single dispatcher_loop' do
    collection.push(dispatcher_loop)
    dispatcher_loop2 = double.as_null_object
    collection.push(dispatcher_loop2)
    dispatcher_loop.should_receive(:wakeup)
    dispatcher_loop2.should_receive(:wakeup)
    collection.pop
  end

  it 'stops all dispatcher  detetcloops' do
    collection.push(dispatcher_loop)
    dispatcher_loop.should_receive(:stop)
    dispatcher_loop.should_receive(:wakeup)
    dispatcher_loop.should_receive(:wait)
    collection.stop
  end
end
