require 'functional_spec_helper'

describe 'WPNs' do
  let(:app) { Rpush::Wpns::App.new }
  let(:notification_with_data) { Rpush::Wpns::Notification.new }
  let(:notification_with_alert) { Rpush::Wpns::Notification.new }
  let(:response) { double(Net::HTTPResponse, code: 200) }
  let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }

  before do
    app.name = 'test'
    app.save!

    notification_with_data.app = app
    notification_with_data.uri = 'http://sn1.notify.live.net/'
    notification_with_data.data = { title: "MyApp", body: "test", param: "new_user" }
    notification_with_data.save!

    notification_with_alert.app = app
    notification_with_alert.uri = 'http://sn1.notify.live.net/'
    notification_with_alert.alert = "Hello world!"
    notification_with_alert.save!

    Net::HTTP::Persistent.stub(new: http)
  end

  it 'delivers a notification with data successfully' do
    response.stub(to_hash: { 'x-notificationstatus' => ['Received'] })

    expect do
      Rpush.push
      notification_with_data.reload
    end.to change(notification_with_data, :delivered).to(true)
  end

  it 'fails to deliver a notification with data successfully' do
    response.stub(code: 400)

    expect do
      Rpush.push
      notification_with_data.reload
    end.to_not change(notification_with_data, :delivered).to(true)
  end

  it 'delivers a notification with an alert successfully' do
    response.stub(to_hash: { 'x-notificationstatus' => ['Received'] })

    expect do
      Rpush.push
      notification_with_alert.reload
    end.to change(notification_with_alert, :delivered).to(true)
  end

  it 'fails to deliver a notification with an alert successfully' do
    response.stub(code: 400)

    expect do
      Rpush.push
      notification_with_alert.reload
    end.to_not change(notification_with_alert, :delivered).to(true)
  end

end
