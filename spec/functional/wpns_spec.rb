require 'functional_spec_helper'

describe 'GCM' do
  let(:app) { Rpush::Wpns::App.new }
  let(:notification) { Rpush::Wpns::Notification.new }
  let(:response) { double(Net::HTTPResponse, code: 200) }
  let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }

  before do
    app.name = 'test'
    app.save!

    notification.app = app
    notification.uri = 'http://sn1.notify.live.net/'
    notification.alert = 'test'
    notification.save!

    Net::HTTP::Persistent.stub(new: http)
  end

  it 'delivers a notification successfully' do
    response.stub(to_hash: { 'x-notificationstatus' => ['Received'] })

    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end

  it 'fails to deliver a notification successfully' do
    response.stub(code: 400)

    expect do
      Rpush.push
      notification.reload
    end.to_not change(notification, :delivered).to(true)
  end
end
