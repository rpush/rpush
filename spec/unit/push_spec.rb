# frozen_string_literal: true

require 'unit_spec_helper'

describe Rpush, 'push' do
  before do
    allow(Rpush::Daemon::Synchronizer).to receive_messages(sync: nil)
    allow(Rpush::Daemon::AppRunner).to receive_messages(wait: nil)
    allow(Rpush::Daemon::Feeder).to receive_messages(start: nil)
  end

  it 'sets the push config option to true' do
    described_class.push
    expect(described_class.config.push).to be(true)
  end

  it 'initializes the daemon' do
    expect(Rpush::Daemon).to receive(:common_init)
    described_class.push
  end

  it 'syncs' do
    expect(Rpush::Daemon::Synchronizer).to receive(:sync)
    described_class.push
  end

  it 'starts the feeder' do
    expect(Rpush::Daemon::Feeder).to receive(:start)
    described_class.push
  end

  it 'stops on the app runner' do
    expect(Rpush::Daemon::AppRunner).to receive(:stop)
    described_class.push
  end
end
