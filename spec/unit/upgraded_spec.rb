require 'unit_spec_helper'

describe Rpush::Upgraded do
  let(:logger) { double(:logger, :warn => nil) }
  let(:config) { double(:config) }

  before do
    Rails.stub(:root).and_return('/rails_root')
    Rpush.stub(:logger => logger, :config => config)
  end

  it 'prints a warning and exists if rapns has not been upgraded' do
    Rpush::App.stub(:count).and_raise(ActiveRecord::StatementInvalid, "test")
    Rpush::Upgraded.stub(:puts)
    Rpush::Upgraded.should_receive(:exit).with(1)
    Rpush::Upgraded.check(:exit => true)
  end

  it 'does not exit if Rapns has not been upgraded and :exit is false' do
    Rpush.config.stub(:embedded => true)
    Rpush::App.stub(:count).and_raise(ActiveRecord::StatementInvalid, "test")
    Rpush::Upgraded.stub(:puts)
    Rpush::Upgraded.should_not_receive(:exit)
    Rpush::Upgraded.check(:exit => false)
  end

  it 'does not exit if Rapns has not been upgraded and is in push mode' do
    Rpush.config.stub(:push => true)
    Rpush::App.stub(:count).and_raise(ActiveRecord::StatementInvalid, "test")
    Rpush::Upgraded.stub(:puts)
    Rpush::Upgraded.should_not_receive(:exit)
    Rpush::Upgraded.check(:exit => false)
  end

  it 'warns if rapns.yml still exists' do
    File.should_receive(:exists?).with('/rails_root/config/rapns/rapns.yml').and_return(true)
    Rpush.logger.should_receive(:warn).with("Since 2.0.0 rapns uses command-line options and a Ruby based configuration file.\nPlease run 'rails g rapns' to generate a new configuration file into config/initializers.\nRemove config/rapns/rapns.yml to avoid this warning.\n")
    Rpush::Upgraded.check(:exit => false)
  end
end
