require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Notification do
  it_behaves_like 'Rpush::Client::Notification'
end if active_record?
