require 'unit_spec_helper'

describe Rpush, 'push' do
  before do
    Rpush::Daemon::Synchronizer.stub(sync: nil)
    Rpush::Daemon::AppRunner.stub(wait: nil)
    Rpush::Daemon::Feeder.stub(start: nil)
  end

  it 'sets the push config option to true' do
    Rpush.push
    Rpush.config.push.should be_true
  end

  it 'initializes the daemon' do
    Rpush::Daemon.should_receive(:common_init)
    Rpush.push
  end

  it 'syncs' do
    Rpush::Daemon::Synchronizer.should_receive(:sync)
    Rpush.push
  end

  it 'starts the feeder' do
    Rpush::Daemon::Feeder.should_receive(:start)
    Rpush.push
  end

  it 'stops on the app runner' do
    Rpush::Daemon::AppRunner.should_receive(:stop)
    Rpush.push
  end

  it 'overrides the default config options with those given as a hash' do
    Rpush.config.batch_size = 20
    expect { Rpush.push(batch_size: 10) }.to change(Rpush.config, :batch_size).to(10)
  end
end
