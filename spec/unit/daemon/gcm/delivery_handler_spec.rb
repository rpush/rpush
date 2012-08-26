require "unit_spec_helper"
require File.dirname(__FILE__) + '/../delivery_handler_shared.rb'

describe Rapns::Daemon::Gcm::DeliveryHandler do
  it_should_behave_like 'an DeliveryHandler sublcass'
end