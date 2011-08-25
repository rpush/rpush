require "spec_helper"

describe Rapns::Daemon do
  module Rails
  end

  before do
    Rapns::Daemon::Configuration.stub(:load)
    Rapns::Daemon::Configuration.stub(:certificate)
    Rapns::Daemon::Certificate.stub(:load)
    Rails.stub(:root).and_return("/rails_root")
  end

  it "should load the configuration" do
    Rapns::Daemon::Configuration.should_receive(:load).with("development", "/rails_root/config/rapns/rapns.yml")
    Rapns::Daemon.start("development", {})
  end

  it "should load the certificate" do
    Rapns::Daemon::Configuration.stub(:certificate).and_return("/rails_root/config/rapns/development.pem")
    Rapns::Daemon::Certificate.should_receive(:load).with("/rails_root/config/rapns/development.pem")
    Rapns::Daemon.start("development", {})
  end
end