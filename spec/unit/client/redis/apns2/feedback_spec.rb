require 'unit_spec_helper'

describe Rpush::Client::Redis::Apns2::Feedback do
  it_behaves_like 'Rpush::Client::Apns2::Feedback'
end if redis?
