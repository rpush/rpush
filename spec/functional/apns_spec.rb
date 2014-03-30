require 'functional_spec_helper'

describe 'APNs' do
  let(:app) { Rpush::Apns::App.new }
  let(:notification) { Rpush::Apns::Notification.new }
  let(:tcp_socket) { double(TCPSocket, setsockopt: nil, close: nil) }
  let(:ssl_socket) { double(OpenSSL::SSL::SSLSocket, :sync= => nil, connect: nil,
    write: nil, flush: nil, read: nil, close: nil) }

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
    TCPSocket.stub(new: tcp_socket)
    OpenSSL::SSL::SSLSocket.stub(new: ssl_socket)
    IO.stub(select: nil)
  end

  it 'delivers a notification successfully' do
    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end

  it 'fails to deliver a notification successfully' do
    IO.stub(select: true)
    ssl_socket.stub(read: [8, 4, 69].pack('ccN'))

    expect do
      Rpush.push
      notification.reload
    end.to_not change(notification, :delivered).to(true)
  end

  it 'receives feedback' do
    tuple = "N\xE3\x84\r\x00 \x83OxfU\xEB\x9F\x84aJ\x05\xAD}\x00\xAF1\xE5\xCF\xE9:\xC3\xEA\a\x8F\x1D\xA4M*N\xB0\xCE\x17"
    allow(ssl_socket).to receive(:read).and_return(tuple, nil)

    expect do
      Rpush.apns_feedback
    end.to change(Rpush::Apns::Feedback, :count).to(1)
  end
end
