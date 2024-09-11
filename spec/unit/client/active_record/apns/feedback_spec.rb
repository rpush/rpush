require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Apns::Feedback do
    it_behaves_like 'Rpush::Client::Apns::Feedback'
  end
end
