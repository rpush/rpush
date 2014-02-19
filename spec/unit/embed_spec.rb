require 'spec_helper'

describe Rpush, 'embed' do
  before do
    Rpush::Daemon.stub(:start)
    Kernel.stub(:at_exit)
  end

  it 'sets the embedded config option to true' do
    Rpush.embed
    Rpush.config.embedded.should be_true
  end

  it 'starts the daemon' do
    Rpush::Daemon.should_receive(:start)
    Rpush.embed
  end

  it 'overrides the default config options with those given as a hash' do
    Rpush.config.push_poll = 4
    expect { Rpush.embed(:push_poll => 2) }.to change(Rpush.config, :push_poll).to(2)
  end
end

describe Rpush, 'shutdown' do
  before { Rpush.config.embedded = true }

  it 'shuts down the daemon' do
    Rpush::Daemon.should_receive(:shutdown)
    Rpush.shutdown
  end
end

describe Rpush, 'sync' do
  before { Rpush.config.embedded = true }

  it 'syncs the AppRunner' do
    Rpush::Daemon::AppRunner.should_receive(:sync)
    Rpush.sync
  end
end

describe Rpush, 'debug' do
  before { Rpush.config.embedded = true }

  it 'debugs the AppRunner' do
    Rpush::Daemon::AppRunner.should_receive(:debug)
    Rpush.debug
  end
end
