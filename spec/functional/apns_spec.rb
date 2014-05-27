require 'functional_spec_helper'

describe 'APNs' do
  let(:app) { Rpush::Apns::App.new }
  let(:notification) { Rpush::Apns::Notification.new }
  let(:tcp_socket) { double(TCPSocket, setsockopt: nil, close: nil) }
  let(:ssl_socket) do double(OpenSSL::SSL::SSLSocket, :sync= => nil, connect: nil,
                                                      write: nil, flush: nil, read: nil, close: nil)
  end
  let(:io_double) { double(select: nil) }

  before do
    app.certificate = TEST_CERT
    app.name = 'test'
    app.environment = 'sandbox'
    app.save!

    notification.app = app
    notification.alert = 'test'
    notification.device_token = 'a' * 64
    notification.save!

    Rails.stub(root: File.expand_path(File.join(File.dirname(__FILE__), '..', 'tmp')))
    Rpush.config.logger = ::Logger.new(STDOUT)

    stub_tcp_connection
  end

  def stub_tcp_connection
    Rpush::Daemon::TcpConnection.any_instance.stub(connect_socket: [tcp_socket, ssl_socket])
    Rpush::Daemon::TcpConnection.any_instance.stub(setup_ssl_context: double.as_null_object)
    stub_const('Rpush::Daemon::TcpConnection::IO', io_double)
  end

  it 'delivers a notification successfully' do
    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end

  it 'fails to deliver a notification successfully' do
    io_double.stub(select: true)
    ssl_socket.stub(read: [8, 4, 69].pack('ccN'))

    expect do
      Rpush.push
      notification.reload
    end.to_not change(notification, :delivered).to(true)
  end

  it 'receives feedback' do
    tuple = "N\xE3\x84\r\x00 \x83OxfU\xEB\x9F\x84aJ\x05\xAD}\x00\xAF1\xE5\xCF\xE9:\xC3\xEA\a\x8F\x1D\xA4M*N\xB0\xCE\x17"
    allow(ssl_socket).to receive(:read).and_return(tuple, nil)
    Rpush.apns_feedback
    feedback = Rpush::Apns::Feedback.all
    feedback.should_not be_empty
  end
end
