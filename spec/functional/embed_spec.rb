require 'functional_spec_helper'

describe 'embedding' do
  def create_app
    app = Rpush::Apns2::App.new
    app.certificate = TEST_CERT
    app.name = 'test'
    app.environment = 'development'
    app.bundle_id = 'com.example.app'
    app.save!
    app
  end

  let(:fake_device_token) { 'a' * 108 }
  let(:notification_data) { nil }

  def create_notification
    notification = Rpush::Apns2::Notification.new
    notification.app = app
    notification.sound = 'default'
    notification.alert = 'test'
    notification.device_token = fake_device_token
    notification.data = notification_data
    notification.content_available = 1
    notification.save!
    notification
  end

  let(:app) { create_app }
  let(:notification) { create_notification }

  let(:fake_client) {
    double(
      prepare_request: fake_http2_request,
      close:           'ok',
      call_async:      'ok',
      join:            'ok',
      on:              'ok'
    )
  }
  let(:fake_http2_request) { double }
  let(:fake_http_resp_headers) {
    {
      ":status" => "200",
      "apns-id"=>"C6D65840-5E3F-785A-4D91-B97D305C12F6"
    }
  }
  let(:fake_http_resp_body) { '' }

  before do
    Rpush.config.push_poll = 0.5

    allow(NetHttp2::Client).
      to receive(:new).and_return(fake_client)
    allow(fake_http2_request).
      to receive(:on).with(:headers).
      and_yield(fake_http_resp_headers)
    allow(fake_http2_request).
      to receive(:on).with(:body_chunk).
      and_yield(fake_http_resp_body)
    allow(fake_http2_request).
      to receive(:on).with(:close).
      and_yield

    Rpush.embed
  end

  after do
    timeout { Rpush.shutdown }
  end

  it 'delivers a notification successfully' do
    expect do
      until notification.delivered
        notification.reload
        sleep 0.1
      end
    end.to change(notification, :delivered).to(true)
  end
end
