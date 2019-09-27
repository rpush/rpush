require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Adm::Notification do
  it_behaves_like 'Rpush::Client::Adm::Notification'
end if active_record?
