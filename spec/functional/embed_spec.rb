require 'unit_spec_helper'

describe 'embedding' do
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
    TCPSocket.stub(:new => tcp_socket)
    OpenSSL::SSL::SSLSocket.stub(:new => ssl_socket)
    IO.stub(:select => nil)
    Rpush::Daemon::Apns::FeedbackReceiver.stub(:new => double.as_null_object)
  end

  it 'delivers a notification successfully' do
    expect do
      Rpush.embed

      begin
        Timeout.timeout(5) do
          while !notification.delivered
            notification.reload
            sleep 0.1
          end
        end
      rescue Timeout::Error
        Rpush.shutdown
        raise
      end

      Rpush.shutdown
    end.to change(notification, :delivered).to(true)
  end
end
