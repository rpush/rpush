require 'functional_spec_helper'

describe 'APNs' do
  let(:app) { create_app }
  let(:tcp_socket) { double(TCPSocket, setsockopt: nil, close: nil) }
  let(:ssl_socket) { double(OpenSSL::SSL::SSLSocket, :sync= => nil, connect: nil, write: nil, flush: nil, read: nil, close: nil) }
  let(:io_double) { double(select: nil) }
  let(:delivered_ids) { [] }
  let(:failed_ids) { [] }
  let(:retry_ids) { [] }

  before do
    Rpush.config.push_poll = 0.5
    stub_tcp_connection(tcp_socket, ssl_socket, io_double)
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

  def wait
    sleep 0.1
  end

  def wait_for_notification_to_deliver(notification)
    timeout { wait until delivered_ids.include?(notification.id) }
  end

  def wait_for_notification_to_fail(notification)
    timeout { wait until failed_ids.include?(notification.id) }
  end

  def wait_for_notification_to_retry(notification)
    timeout { wait until retry_ids.include?(notification.id) }
  end

  def fail_notification(notification)
    allow(ssl_socket).to receive_messages(read: [8, 4, notification.id].pack('ccN'))
    enable_io_select
  end

  def enable_io_select
    called = false
    allow(io_double).to receive(:select) do
      if called
        nil
      else
        called = true
      end
    end
  end

  it 'delivers a notification successfully' do
    notification = create_notification
    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end

  describe 'delivery failures' do
    before do
      Rpush.reflect do |on|
        on.notification_delivered do |n|
          delivered_ids << n.id
        end

        on.notification_id_failed do |_, n_id|
          failed_ids << n_id
        end

        on.notification_id_will_retry do |_, n_id|
          retry_ids << n_id
        end

        on.notification_will_retry do |n|
          retry_ids << n.id
        end
      end

      Rpush.embed
    end

    after do
      timeout { Rpush.shutdown }
    end

    it 'fails to deliver a notification' do
      notification = create_notification
      wait_for_notification_to_deliver(notification)
      fail_notification(notification)
      wait_for_notification_to_fail(notification)
    end
  end
end
