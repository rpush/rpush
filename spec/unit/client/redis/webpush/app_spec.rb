require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Webpush::App do
    it_behaves_like 'Rpush::Client::Webpush::App'
  end
end
