require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Notification do
    it_behaves_like 'Rpush::Client::Notification'
  end
end
