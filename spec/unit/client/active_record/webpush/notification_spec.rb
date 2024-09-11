require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Webpush::Notification do
    it_behaves_like 'Rpush::Client::Webpush::Notification'
    it_behaves_like 'Rpush::Client::ActiveRecord::Notification'
  end
end
