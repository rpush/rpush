require 'unit_spec_helper'

describe Rpush::Daemon::Reflectable do
  class TestReflectable
    include Rpush::Daemon::Reflectable
  end

  let(:logger) { double(error: nil) }
  let(:test_reflectable) { TestReflectable.new }

  before do
    Rpush.reflections.stub(:__dispatch)
    Rpush.stub(logger: logger)
  end

  it 'dispatches the given reflection' do
    Rpush.reflections.should_receive(:__dispatch).with(:error)
    test_reflectable.reflect(:error)
  end

  it 'logs errors raise by the reflection' do
    error = StandardError.new
    Rpush.reflections.stub(:__dispatch).and_raise(error)
    Rpush.logger.should_receive(:error).with(error)
    test_reflectable.reflect(:error)
  end
end
