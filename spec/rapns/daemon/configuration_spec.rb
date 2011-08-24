require "spec_helper"

describe Rapns::Daemon::Configuration do

  it "should raise an error if the configuration file does not exist" do
    expect { Rapns::Daemon::Configuration.load("production", "/tmp/rapns-non-existant-file") }.to raise_error(Rapns::ConfigurationError, "/tmp/rapns-non-existant-file does not exist. Have you run 'rails g rapns'?")
  end

  it "should raise an error if the configuration is not configured for the environment" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => {}})
    expect { Rapns::Daemon::Configuration.load("development", "/some/config.yml") }.to raise_error(Rapns::ConfigurationError, "Configuration for environment 'development' not specified in /some/config.yml")
  end

  it "should raise an error if the host is not configured" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => {"host" => nil, "port" => 123}})
    expect { Rapns::Daemon::Configuration.load("production", "/some/config.yml") }.to raise_error(Rapns::ConfigurationError, "'host' not specified for environment 'production' in /some/config.yml")
  end

  it "should raise an error if the port is not configured" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => {"port" => nil, "host" => "localhost"}})
    expect { Rapns::Daemon::Configuration.load("production", "/some/config.yml") }.to raise_error(Rapns::ConfigurationError, "'port' not specified for environment 'production' in /some/config.yml")
  end

  it "should set the configured host" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => {"port" => 123, "host" => "localhost"}})
    Rapns::Daemon::Configuration.load("production", "/some/config.yml")
    Rapns::Daemon::Configuration.host.should == "localhost"
  end

  it "should set the configured port" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => {"port" => 123, "host" => "localhost"}})
    Rapns::Daemon::Configuration.load("production", "/some/config.yml")
    Rapns::Daemon::Configuration.port.should == 123
  end
end