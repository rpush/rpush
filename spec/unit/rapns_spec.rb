require 'unit_spec_helper'

describe Rapns do
  it "lazy initializes the logger" do
    Rapns.config.stub(:airbrake_notify => true, :foreground => true)
    Rapns::Logger.should_receive(:new).with(:foreground => true, :airbrake_notify => true)
    Rapns.logger
  end
end
