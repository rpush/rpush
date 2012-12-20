require 'unit_spec_helper'

describe Rapns, 'embed' do
  before do
    Rapns::Daemon.stub(:start)
    Kernel.stub(:at_exit)
  end

  it 'sets the embedded config option to true' do
    Rapns.embed
    Rapns.config.embedded.should be_true
  end

  it 'starts the daemon' do
    Rapns::Daemon.should_receive(:start)
    Rapns.embed
  end

  it 'overrides the default config options with those given as a hash' do
    Rapns.config.push_poll = 4
    expect { Rapns.embed(:push_poll => 2) }.to change(Rapns.config, :push_poll).to(2)
  end
end

describe Rapns, 'shutdown' do
  it 'shuts down the daemon' do
    Rapns::Daemon.should_receive(:shutdown)
    Rapns.shutdown
  end
end
