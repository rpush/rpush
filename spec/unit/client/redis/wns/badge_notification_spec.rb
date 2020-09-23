require 'unit_spec_helper'

describe Rpush::Client::Redis::Wns::BadgeNotification do
  let(:notification) do
    notif = Rpush::Client::Redis::Wns::BadgeNotification.new
    notif.app  = Rpush::Client::Redis::Wns::App.new(name: "aname")
    notif.uri  = 'https://db5.notify.windows.com/?token=TOKEN'
    notif.badge = 42
    notif
  end

  it 'should allow a notification without data' do
    skip "Doesn't work on Redis yet"
    expect(notification.valid?).to be(true)
  end
end if redis?
