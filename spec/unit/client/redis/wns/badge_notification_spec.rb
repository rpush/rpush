# frozen_string_literal: true

require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Wns::BadgeNotification do
    it_behaves_like 'Rpush::Client::Wns::BadgeNotification'
  end
end
