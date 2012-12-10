require 'unit_spec_helper'

describe Rapns do
  let(:config) { stub }

  before { Rapns.stub(:configuration => config) }

  it 'can yields a configuration block' do
    expect { |b| Rapns.configure(&b) }.to yield_with_args(config)
  end
end

describe Rapns::Configuration do
  let(:config) { Rapns::Configuration.new }

  it 'configures a feedback callback' do
    b = Proc.new {}
    config.on_feedback(&b)
    config.feedback_callback.should == b
  end
end
