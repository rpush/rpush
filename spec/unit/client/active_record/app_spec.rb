require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::App do
    it_behaves_like 'Rpush::Client::App'
  end
end
