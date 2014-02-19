require 'unit_spec_helper'

describe Rpush do
  it "lazy initializes the logger" do
    Rpush.config.stub(:foreground => true)
    Rpush::Logger.should_receive(:new).with(:foreground => true)
    Rpush.logger
  end
end
