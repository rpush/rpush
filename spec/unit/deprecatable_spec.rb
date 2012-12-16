require 'unit_spec_helper'

describe Rapns::Deprecatable do
  class HasDeprecatedMethod
    include Rapns::Deprecatable

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
    Rapns::Deprecation.stub(:warn)
  end

  it 'warns the method is deprecated when called' do
    Rapns::Deprecation.should_receive(:warn).with("deprecated_method is deprecated and will be removed from Rapns 4.0.")
    klass.deprecated_method
  end

  it 'calls the original method' do
    klass.deprecated_method
    klass.original_called?.should be_true
  end
end
