require 'unit_spec_helper'
require File.dirname(__FILE__) + '/../app_runner_shared.rb'

describe Rapns::Daemon::Gcm::AppRunner do
  it_behaves_like 'an AppRunner subclass'

  let(:app_class) { Rapns::Gcm::App }
  let(:app) { app_class.new }
  let(:runner) { Rapns::Daemon::Gcm::AppRunner.new(app) }
  let(:handler) { stub(:start => nil, :stop => nil, :queue= => nil) }

  before do
    Rapns::Daemon::Gcm::DeliveryHandler.stub(:new => handler)
  end
end