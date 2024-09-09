# frozen_string_literal: true

require 'unit_spec_helper'

describe Rpush::Deprecation do
  it 'prints a warning' do
    expect($stderr).to receive(:puts).with("DEPRECATION WARNING: msg")
    described_class.warn("msg")
  end

  it 'does not print a warning when muted' do
    expect($stderr).not_to receive(:puts)
    described_class.muted do
      described_class.warn("msg")
    end
  end
end
