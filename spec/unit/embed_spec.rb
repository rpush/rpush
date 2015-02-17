require 'unit_spec_helper'

describe Rpush, 'embed' do
  before do
    allow(Rpush::Daemon).to receive_messages(start: nil, shutdown: nil)
    allow(Kernel).to receive(:at_exit)
  end

  after { Rpush.shutdown }

  it 'sets the embedded config option to true' do
    Rpush.embed
    expect(Rpush.config.embedded).to eq(true)
  end

  it 'starts the daemon' do
    expect(Rpush::Daemon).to receive(:start)
    Rpush.embed
  end

  it 'overrides the default config options with those given as a hash' do
    Rpush::Deprecation.muted do
      Rpush.config.push_poll = 4
      expect { Rpush.embed(push_poll: 2) }.to change(Rpush.config, :push_poll).to(2)
    end
  end
end

describe Rpush, 'shutdown' do
  before { Rpush.config.embedded = true }

  it 'shuts down the daemon' do
    expect(Rpush::Daemon).to receive(:shutdown)
    Rpush.shutdown
  end
end

describe Rpush, 'sync' do
  before { Rpush.config.embedded = true }

  it 'syncs' do
    expect(Rpush::Daemon::Synchronizer).to receive(:sync)
    Rpush.sync
  end
end

describe Rpush, 'debug' do
  before { Rpush.config.embedded = true }

  it 'debugs the AppRunner' do
    expect(Rpush::Daemon::AppRunner).to receive(:debug)
    Rpush.debug
  end
end
