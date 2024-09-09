require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Adm::Notification do
    it_behaves_like 'Rpush::Client::Adm::Notification'
  end
end
