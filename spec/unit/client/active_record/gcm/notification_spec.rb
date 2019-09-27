require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Gcm::Notification do
  it_behaves_like 'Rpush::Client::Gcm::Notification'
  it_behaves_like 'Rpush::Client::ActiveRecord::Notification'
end if active_record?
