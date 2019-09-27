# encoding: US-ASCII

require "unit_spec_helper"

describe Rpush::Client::Redis::Apns::Notification do
  it_behaves_like 'Rpush::Client::Apns::Notification'
end if redis?
