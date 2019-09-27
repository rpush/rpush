require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Wns::RawNotification do
  it_behaves_like 'Rpush::Client::Wns::RawNotification'
end if active_record?
