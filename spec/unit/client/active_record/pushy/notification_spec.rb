require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Pushy::Notification do
    it_behaves_like 'Rpush::Client::Pushy::Notification'
    it_behaves_like 'Rpush::Client::ActiveRecord::Notification'
  end
end
