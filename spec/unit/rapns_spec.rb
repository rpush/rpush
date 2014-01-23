require 'unit_spec_helper'

describe Rapns do
  it "lazy initializes the logger" do
    Rapns.config.stub(:foreground => true)
    Rapns::Logger.should_receive(:new).with(:foreground => true)
    Rapns.logger
  end
end
