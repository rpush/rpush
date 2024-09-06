require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Fcm::Notification do
  it_behaves_like 'Rpush::Client::Fcm::Notification'
  it_behaves_like 'Rpush::Client::ActiveRecord::Notification'

  subject(:notification) { described_class.new }
  let(:app) { Rpush::Fcm::App.create!(name: 'test', auth_key: 'abc') }

end if active_record?
