require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Apns::Feedback do
    it_behaves_like 'Rpush::Client::Apns::Feedback'
  end
end
