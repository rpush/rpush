require 'unit_spec_helper'
require File.dirname(__FILE__) + '/../app_runner_shared.rb'

describe Rapns::Daemon::Wpns::AppRunner do
  it_behaves_like 'an AppRunner subclass'

  let(:app_class) { Rapns::Wpns::App }
  let(:app) { app_class.new }
  let(:runner) { Rapns::Daemon::Wpns::AppRunner.new(app) }
  let(:handler) { double(:start => nil, :queue= => nil, :wakeup => nil, :wait => nil) }
  let(:handler_collection) { double(:handler_collection, :push => nil, :size => 1, :stop => nil) }
  let(:logger) { double(:info => nil) }

  before do
    Rapns.stub(:logger => logger)
    Rapns::Daemon::Wpns::DeliveryHandler.stub(:new => handler)
    Rapns::Daemon::DeliveryHandlerCollection.stub(:new => handler_collection)
  end
end
