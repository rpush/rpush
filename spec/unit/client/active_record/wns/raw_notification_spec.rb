# frozen_string_literal: true

require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Wns::RawNotification do
    let(:notification) do
      notif = described_class.new
      notif.app  = Rpush::Wns::App.create!(name: "MyApp", client_id: "someclient", client_secret: "somesecret")
      notif.uri  = 'https://db5.notify.windows.com/?token=TOKEN'
      notif.data = { foo: 'foo', bar: 'bar' }
      notif
    end

    it_behaves_like 'Rpush::Client::Wns::RawNotification'

    it 'does not allow the size of payload over 5 KB' do
      allow(notification).to receive(:payload_data_size).and_return(5121)
      expect(notification.valid?).to be(false)
    end
  end
end
