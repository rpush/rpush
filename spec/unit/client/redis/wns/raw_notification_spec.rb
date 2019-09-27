require 'unit_spec_helper'

describe Rpush::Client::Redis::Wns::RawNotification do
  it_behaves_like 'Rpush::Client::Wns::RawNotification'
end if redis?
