require 'unit_spec_helper'

describe Rpush::Client::Redis::Apns2::App do
  it_behaves_like 'Rpush::Client::Apns::App'
end if redis?
