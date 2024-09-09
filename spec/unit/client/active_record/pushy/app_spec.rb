# frozen_string_literal: true

require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Pushy::App do
    it_behaves_like 'Rpush::Client::Pushy::App'
    it_behaves_like 'Rpush::Client::ActiveRecord::App'
  end
end
