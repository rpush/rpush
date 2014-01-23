require 'unit_spec_helper'

describe Rapns::Daemon::Dispatcher::Tcp do
  let(:app) { double }
  let(:delivery) { double(:perform => nil) }
  let(:delivery_class) { double(:new => delivery) }
  let(:notification) { double }
  let(:batch) { double }
  let(:connection) { double(Rapns::Daemon::TcpConnection, :connect => nil) }
  let(:host) { 'localhost' }
  let(:port) { 1234 }
  let(:host_proc) { Proc.new { |app| [host, port] } }
  let(:dispatcher) { Rapns::Daemon::Dispatcher::Tcp.new(app, delivery_class, :host => host_proc) }

  before { Rapns::Daemon::TcpConnection.stub(:new => connection) }

  describe 'dispatch' do
    it 'lazily connects the socket' do
      Rapns::Daemon::TcpConnection.should_receive(:new).with(app, host, port).and_return(connection)
      connection.should_receive(:connect)
      dispatcher.dispatch(notification, batch)
    end

    it 'delivers the notification' do
      delivery_class.should_receive(:new).with(app, connection, notification, batch).and_return(delivery)
      delivery.should_receive(:perform)
      dispatcher.dispatch(notification, batch)
    end
  end

  describe 'cleanup' do
    it 'closes the connection' do
      dispatcher.dispatch(notification, batch) # lazily initialize connection
      connection.should_receive(:close)
      dispatcher.cleanup
    end
  end
end
