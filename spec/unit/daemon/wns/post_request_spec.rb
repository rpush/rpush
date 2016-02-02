require 'unit_spec_helper'

describe Rpush::Daemon::Wns::PostRequest do
  let(:app) do
    Rpush::Wns::App.create!(
      name: "MyApp",
      client_id: "someclient",
      client_secret: "somesecret",
      access_token: "access_token",
      access_token_expiration: Time.now + (60 * 10)
    )
  end

  context 'Notification' do
    let(:notification) do
      Rpush::Wns::Notification.create!(
        app: app,
        data: {
          title: "MyApp",
          body: "Example notification"
        },
        uri: "http://some.example/"
      )
    end

    it 'creates a request characteristic for toast notification' do
      request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
      expect(request['X-WNS-Type']).to eq('wns/toast')
      expect(request['Content-Type']).to eq('text/xml')
      expect(request.body).to include('<toast>')
      expect(request.body).to include('MyApp')
      expect(request.body).to include('Example notification')
    end
  end

  context 'RawNotification' do
    let(:notification) do
      Rpush::Wns::RawNotification.create!(
        app: app,
        data: { foo: 'foo', bar: 'bar' },
        uri: "http://some.example/"
      )
    end

    it 'creates a request characteristic for raw notification' do
      request = Rpush::Daemon::Wns::PostRequest.create(notification, 'token')
      expect(request['X-WNS-Type']).to eq('wns/raw')
      expect(request['Content-Type']).to eq('application/octet-stream')
      expect(request.body).to eq("{\"foo\":\"foo\",\"bar\":\"bar\"}")
    end
  end
end
