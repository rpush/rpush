require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Fcm::App do
    it_behaves_like 'Rpush::Client::Fcm::App'
    it_behaves_like 'Rpush::Client::ActiveRecord::App'
  end
end
