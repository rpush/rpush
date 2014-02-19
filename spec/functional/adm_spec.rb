require 'functional_spec_helper'

describe 'ADM' do
  let(:app) { Rpush::Adm::App.new }
  let(:notification) { Rpush::Adm::Notification.new }
  let(:response) { double(Net::HTTPResponse, code: 200) }
  let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }

  before do
    app.name = 'test'
    app.client_id = 'abc'
    app.client_secret = '123'
    app.save!

    notification.app = app
    notification.registration_ids = ['foo']
    notification.data = { message: 'test' }
    notification.save!

    Rails.stub(root: File.expand_path(File.join(File.dirname(__FILE__), '..', 'tmp')))
    Rpush.config.logger = ::Logger.new(STDOUT)

    Net::HTTP::Persistent.stub(new: http)
  end

  it 'delivers a notification successfully' do
    response.stub(body: JSON.dump({registrationID: notification.registration_ids.first.to_s}))

    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end

  it 'fails to deliver a notification successfully' do
    response.stub(code: 400, body: JSON.dump({reason: 'error', registrationID: notification.registration_ids.first.to_s}))

    expect do
      Rpush.push
      notification.reload
    end.to_not change(notification, :delivered).to(true)
  end
end
