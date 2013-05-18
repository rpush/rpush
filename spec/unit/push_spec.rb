require 'unit_spec_helper'

describe Rapns, 'push' do
  before do
    Rapns::Upgraded.stub(:check => nil)
    Rapns::Daemon::AppRunner.stub(:sync => nil, :wait => nil)
    Rapns::Daemon::Feeder.stub(:start => nil)
  end

  it 'sets the push config option to true' do
    Rapns.push
    Rapns.config.push.should be_true
  end

  it 'initializes the store' do
    Rapns::Daemon.should_receive(:initialize_store)
    Rapns.push
  end

  it 'syncs the app runner' do
    Rapns::Daemon::AppRunner.should_receive(:sync)
    Rapns.push
  end

  it 'starts the feeder' do
    Rapns::Daemon::Feeder.should_receive(:start)
    Rapns.push
  end

  it 'waits on the app runner' do
    Rapns::Daemon::AppRunner.should_receive(:wait)
    Rapns.push
  end

  it 'stops on the app runner' do
    Rapns::Daemon::AppRunner.should_receive(:stop)
    Rapns.push
  end

  it 'overrides the default config options with those given as a hash' do
    Rapns.config.batch_size = 20
    expect { Rapns.push(:batch_size => 10) }.to change(Rapns.config, :batch_size).to(10)
  end
end
