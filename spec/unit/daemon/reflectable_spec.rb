require 'unit_spec_helper'

describe Rapns::Daemon::Reflectable do
  class TestReflectable
    include Rapns::Daemon::Reflectable
  end

  let(:logger) { double(:error => nil) }
  let(:test_reflectable) { TestReflectable.new }

  before do
    Rapns.reflections.stub(:__dispatch)
    Rapns.stub(:logger => logger)
  end

  it 'dispatches the given reflection' do
    Rapns.reflections.should_receive(:__dispatch).with(:error)
    test_reflectable.reflect(:error)
  end

  it 'logs errors raise by the reflection' do
    error = StandardError.new
    Rapns.reflections.stub(:__dispatch).and_raise(error)
    Rapns.logger.should_receive(:error).with(error)
    test_reflectable.reflect(:error)
  end
end
