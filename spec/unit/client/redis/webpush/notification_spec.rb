require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Webpush::Notification do
    it_behaves_like 'Rpush::Client::Webpush::Notification'
  end
end
