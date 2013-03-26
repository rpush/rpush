require 'unit_spec_helper'

describe Rapns, 'push' do
  before do
    Rapns::Daemon.stub(:start)
    Rapns::Daemon.stub(:shutdown)
  end

  it 'sets the push config option to true' do
    Rapns.push
    Rapns.config.push.should be_true
  end

  it 'starts the daemon' do
    Rapns::Daemon.should_receive(:start)
    Rapns.push
  end

  it 'shuts down the daemon' do
    Rapns::Daemon.should_receive(:shutdown).with(true)
    Rapns.push
  end

  it 'overrides the default config options with those given as a hash' do
    Rapns.config.push_poll = 4
    expect { Rapns.push(:push_poll => 2) }.to change(Rapns.config, :push_poll).to(2)
  end
end
