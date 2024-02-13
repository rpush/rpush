require 'unit_spec_helper'

describe Rpush::Client::Redis::Fcm::Notification do
  it_behaves_like 'Rpush::Client::Fcm::Notification'
end if redis?
