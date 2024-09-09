require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Fcm::Notification do
    let(:app) { Rpush::Fcm::App.create!(name: 'test', auth_key: 'abc') }

    it_behaves_like 'Rpush::Client::Fcm::Notification'
    it_behaves_like 'Rpush::Client::ActiveRecord::Notification'

    subject(:notification) { described_class.new }
  end
end
