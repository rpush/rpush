require 'unit_spec_helper'

describe Rapns::Daemon::Dispatcher::Http do
  let(:app) { double }
  let(:delivery_class) { double }
  let(:notification) { double }
  let(:batch) { double }
  let(:http) { double }
  let(:dispatcher) { Rapns::Daemon::Dispatcher::Http.new(app, delivery_class) }

  before { Net::HTTP::Persistent.stub(:new => http) }

  it 'constructs a new persistent connection' do
    Net::HTTP::Persistent.should_receive(:new)
    Rapns::Daemon::Dispatcher::Http.new(app, delivery_class)
  end

  describe 'dispatch' do
    it 'delivers the notification' do
      delivery = double
      delivery_class.should_receive(:new).with(app, http, notification, batch).and_return(delivery)
      delivery.should_receive(:perform)
      dispatcher.dispatch(notification, batch)
    end
  end

  describe 'cleanup' do
    it 'closes the connection' do
      http.should_receive(:shutdown)
      dispatcher.cleanup
    end
  end
end
