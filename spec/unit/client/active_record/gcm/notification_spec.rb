require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Gcm::Notification do
  it_behaves_like 'Rpush::Client::Gcm::Notification'
  it_behaves_like 'Rpush::Client::ActiveRecord::Notification'

  subject(:notification) { described_class.new }
  let(:app) { Rpush::Gcm::App.create!(name: 'test', auth_key: 'abc') }

  # In Rails 4.2 this value casts to `false` and thus will not be included in
  # the payload. This changed to match Ruby's semantics, and will casts to
  # `true` in Rails 5 and above.
  if ActiveRecord.version <= Gem::Version.new('5')
    it 'accepts non-booleans as a falsey value' do
      notification.dry_run = 'Not a boolean'
      expect(notification.as_json).not_to have_key 'dry_run'
    end
  else
    it 'accepts non-booleans as a truthy value' do
      notification.dry_run = 'Not a boolean'
      expect(notification.as_json['dry_run']).to eq true
    end
  end
end if active_record?
