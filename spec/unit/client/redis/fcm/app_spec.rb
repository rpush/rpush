require 'unit_spec_helper'

describe Rpush::Client::Redis::Fcm::App do
  it_behaves_like 'Rpush::Client::Fcm::App'
end if redis?
