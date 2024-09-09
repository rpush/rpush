# frozen_string_literal: true

require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Wpns::Notification do
    it_behaves_like 'Rpush::Client::Wpns::Notification'
  end
end
