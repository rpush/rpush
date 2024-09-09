# frozen_string_literal: true

require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Apns2::App do
    it_behaves_like 'Rpush::Client::Apns::App'
  end
end
