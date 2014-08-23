require 'functional_spec_helper'

describe 'New app loading' do
  let(:timeout) { 10 }
  let(:app) { create_app }
  let(:tcp_socket) { double(TCPSocket, setsockopt: nil, close: nil) }
  let(:ssl_socket) { double(OpenSSL::SSL::SSLSocket, :sync= => nil, connect: nil, write: nil, flush: nil, read: nil, close: nil) }
  let(:io_double) { double(select: nil) }

  before do
    stub_tcp_connection
  end

  def create_app
    app = Rpush::Apns::App.new
    app.certificate = TEST_CERT
    app.name = 'test'
    app.environment = 'sandbox'
    app.save!
    app
  end

  def create_notification
    notification = Rpush::Apns::Notification.new
    notification.app = app
    notification.alert = 'test'
    notification.device_token = 'a' * 64
    notification.save!
    notification
  end

  def stub_tcp_connection
    Rpush::Daemon::TcpConnection.any_instance.stub(connect_socket: [tcp_socket, ssl_socket])
    Rpush::Daemon::TcpConnection.any_instance.stub(setup_ssl_context: double.as_null_object)
    stub_const('Rpush::Daemon::TcpConnection::IO', io_double)
  end

  def wait_for_notification_to_deliver(notification)
    Timeout.timeout(timeout) do
      until notification.delivered
        sleep 0.1
        notification.reload
      end
    end
  end

  before do
    Rpush.config.push_poll = 0
    Rpush.embed
  end

  it 'delivers a notification successfully' do
    sleep 1 # TODO: Need a better way to detect when the Feeder is running.
    notification = create_notification
    wait_for_notification_to_deliver(notification)
  end

  after { Timeout.timeout(timeout) { Rpush.shutdown } }
end
