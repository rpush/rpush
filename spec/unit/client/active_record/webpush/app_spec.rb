require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Webpush::App do
    it_behaves_like 'Rpush::Client::Webpush::App'
    it_behaves_like 'Rpush::Client::ActiveRecord::App'
  end
end
