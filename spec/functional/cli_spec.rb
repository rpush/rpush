require 'functional_spec_helper'

describe Rpush::CLI do
  def create_app
    app = Rpush::Apns2::App.new
    app.certificate = TEST_CERT
    app.name = 'test'
    app.environment = 'development'
    app.bundle_id = 'com.example.app'
    app.save!
    app
  end

  let(:fake_client) do
    double(
      prepare_request: fake_http2_request,
      close: 'ok',
      call_async: 'ok',
      join: 'ok',
      on: 'ok'
    )
  end
  let(:fake_http2_request) { double }
  let(:fake_http_resp_headers) do
    {
      ":status" => "200",
      "apns-id" => "C6D65840-5E3F-785A-4D91-B97D305C12F6"
    }
  end
  let(:fake_http_resp_body) { '' }

  before do
    create_app
    Rpush.config.push_poll = 0.5

    allow(NetHttp2::Client)
      .to receive(:new).and_return(fake_client)
    allow(fake_http2_request)
      .to receive(:on).with(:headers)
      .and_yield(fake_http_resp_headers)
    allow(fake_http2_request)
      .to receive(:on).with(:body_chunk)
      .and_yield(fake_http_resp_body)
    allow(fake_http2_request)
      .to receive(:on).with(:close)
      .and_yield

    Rpush.embed
  end

  after do
    timeout { Rpush.shutdown }
  end

  describe 'status' do
    it 'prints the status' do
      expect(subject).to receive(:configure_rpush).and_return(true)
      expect(subject).to receive(:puts).with(/app_runners:/)
      subject.status
    end
  end
end
