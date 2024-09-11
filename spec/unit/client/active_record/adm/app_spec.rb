require 'unit_spec_helper'

if active_record?
  describe Rpush::Client::ActiveRecord::Adm::App do
    it_behaves_like 'Rpush::Client::Adm::App'
    it_behaves_like 'Rpush::Client::ActiveRecord::App'
  end
end
