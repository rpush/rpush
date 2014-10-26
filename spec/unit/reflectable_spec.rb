require 'unit_spec_helper'

describe Rpush::Reflectable do
  class TestReflectable
    include Rpush::Reflectable
  end

  let(:logger) { double(error: nil) }
  let(:test_reflectable) { TestReflectable.new }

  before do
    Rpush.reflection_stack[0].stub(:__dispatch)
    Rpush.stub(logger: logger)
  end

  it 'dispatches the given reflection' do
    Rpush.reflection_stack[0].should_receive(:__dispatch).with(:error)
    test_reflectable.reflect(:error)
  end

  it 'logs errors raised by the reflection' do
    error = StandardError.new
    Rpush.reflection_stack[0].stub(:__dispatch).and_raise(error)
    Rpush.logger.should_receive(:error).with(error)
    test_reflectable.reflect(:error)
  end
end
