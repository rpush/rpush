require 'unit_spec_helper'

describe Rpush do
  it "lazy initializes the logger" do
    Rpush::Logger.should_receive(:new)
    Rpush.logger
  end
end
