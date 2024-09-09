# frozen_string_literal: true

require 'unit_spec_helper'

describe Rpush, 'embed' do
  before do
    allow(Rpush::Daemon).to receive_messages(start: nil, shutdown: nil)
    allow(Kernel).to receive(:at_exit)
  end

  after { described_class.shutdown }

  it 'sets the embedded config option to true' do
    described_class.embed
    expect(described_class.config.embedded).to be(true)
  end

  it 'starts the daemon' do
    expect(Rpush::Daemon).to receive(:start)
    described_class.embed
  end
end

describe Rpush, 'shutdown' do
  before { described_class.config.embedded = true }

  it 'shuts down the daemon' do
    expect(Rpush::Daemon).to receive(:shutdown)
    described_class.shutdown
  end
end

describe Rpush, 'sync' do
  before { described_class.config.embedded = true }

  it 'syncs' do
    expect(Rpush::Daemon::Synchronizer).to receive(:sync)
    described_class.sync
  end
end

describe Rpush, 'status' do
  before { described_class.config.embedded = true }

  it 'returns the AppRunner status' do
    expect(Rpush::Daemon::AppRunner).to receive_messages(status: { status: true })
    expect(described_class.status).to eq(status: true)
  end
end
