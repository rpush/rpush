# frozen_string_literal: true

require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Pushy::Notification do
    it_behaves_like 'Rpush::Client::Pushy::Notification'
  end
end
