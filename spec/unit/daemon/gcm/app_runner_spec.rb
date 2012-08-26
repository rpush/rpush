require 'unit_spec_helper'
require File.dirname(__FILE__) + '/../app_runner_shared.rb'

describe Rapns::Daemon::Gcm::AppRunner do
  it_behaves_like 'an AppRunner subclass'
end