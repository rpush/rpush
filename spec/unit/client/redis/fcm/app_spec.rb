# frozen_string_literal: true

require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Fcm::App do
    it_behaves_like 'Rpush::Client::Fcm::App'
  end
end
