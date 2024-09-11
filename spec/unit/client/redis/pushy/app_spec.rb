require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Pushy::App do
    it_behaves_like 'Rpush::Client::Pushy::App'
  end
end
