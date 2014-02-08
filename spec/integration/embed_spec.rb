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
      ::ActiveRecord::Base.clear_all_connections!

      pid = fork do
        Rpush.embed
        sleep 0.5
        Rpush.shutdown
        Kernel.at_exit { exit! } # Don't run any at_exit hooks.
      end

      Process.waitpid(pid)
      notification.reload
    end.to change(notification, :delivered).to(true)
  end
end
