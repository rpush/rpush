require 'unit_spec_helper'
require File.dirname(__FILE__) + '/../app_runner_shared.rb'

describe Rapns::Daemon::Gcm::AppRunner do
  it_behaves_like 'an AppRunner subclass'

  let(:app_class) { Rapns::Gcm::App }
  let(:app) { app_class.new }
  let(:runner) { Rapns::Daemon::Gcm::AppRunner.new(app) }
  let(:handler) { stub(:start => nil, :stop => nil, :wakeup => nil, :wait => nil, :queue= => nil) }
  let(:logger) { stub(:info => nil) }

  before do
    Rapns.stub(:logger => logger)
    Rapns::Daemon::Gcm::DeliveryHandler.stub(:new => handler)
  end
end
