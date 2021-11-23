require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Apns2::App do
  it_behaves_like 'Rpush::Client::Apns2::App'
  it_behaves_like 'Rpush::Client::ActiveRecord::App'
end if active_record?
