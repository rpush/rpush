require 'unit_spec_helper'

describe Rpush::Deprecation do
  it 'prints a warning' do
    STDERR.should_receive(:puts).with("DEPRECATION WARNING: msg")
    Rpush::Deprecation.warn("msg")
  end

  it 'does not print a warning when muted' do
    STDERR.should_not_receive(:puts)
    Rpush::Deprecation.muted do
      Rpush::Deprecation.warn("msg")
    end
  end
end
