require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Gcm::App do
  it_behaves_like 'Rpush::Client::Gcm::App'
end if active_record?
