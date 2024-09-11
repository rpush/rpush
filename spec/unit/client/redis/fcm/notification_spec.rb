require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Fcm::Notification do
    it_behaves_like 'Rpush::Client::Fcm::Notification'
  end
end
