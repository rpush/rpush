require 'functional_spec_helper'

describe 'APNs' do
  let(:app) { create_app }
  let(:tcp_socket) { double(TCPSocket, setsockopt: nil, close: nil) }
  let(:ssl_socket) { double(OpenSSL::SSL::SSLSocket, :sync= => nil, connect: nil, write: nil, flush: nil, read: nil, close: nil) }
  let(:io_double) { double(select: nil) }

  before do
    Rpush.config.push_poll = 0.5

    allow_any_instance_of(Rpush::Daemon::TcpConnection).to receive_messages(connect_socket: [tcp_socket, ssl_socket])
    allow_any_instance_of(Rpush::Daemon::TcpConnection).to receive_messages(setup_ssl_context: double.as_null_object)
    stub_const('Rpush::Daemon::TcpConnection::IO', io_double)
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
    notification.device_token = 'a' * 108
    notification.save!
    notification
  end

  it 'delivers a notification successfully' do
    notification = create_notification
    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end
end
