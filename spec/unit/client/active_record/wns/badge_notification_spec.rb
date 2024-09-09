# frozen_string_literal: true

require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Wns::BadgeNotification do
    it_behaves_like 'Rpush::Client::Wns::BadgeNotification'
  end
end
