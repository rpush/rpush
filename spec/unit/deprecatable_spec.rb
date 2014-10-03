require 'unit_spec_helper'

describe Rpush::Deprecatable do
  class HasDeprecatedMethod
    include Rpush::Deprecatable

    def original_called?
      @called == true
    end

    def deprecated_method
      @called = true
    end
    deprecated(:deprecated_method, '4.0')
  end

  let(:klass) { HasDeprecatedMethod.new }

  before do
    Rpush::Deprecation.stub(:warn)
  end

  it 'warns the method is deprecated when called' do
    Rpush::Deprecation.should_receive(:warn).with(/deprecated_method is deprecated and will be removed from Rpush 4\.0\./)
    klass.deprecated_method
  end

  it 'calls the original method' do
    klass.deprecated_method
    klass.original_called?.should be_true
  end
end
