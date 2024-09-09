# frozen_string_literal: true

require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Apns::App do
    it_behaves_like 'Rpush::Client::Apns::App'
  end
end
