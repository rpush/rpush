require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Wpns::App do
  it_behaves_like 'Rpush::Client::Wpns::App'
end if active_record?
