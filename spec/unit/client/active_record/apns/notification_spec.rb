# encoding: US-ASCII

require "unit_spec_helper"

describe Rpush::Client::ActiveRecord::Apns::Notification do
  it_behaves_like 'Rpush::Client::Apns::Notification'
end if active_record?
