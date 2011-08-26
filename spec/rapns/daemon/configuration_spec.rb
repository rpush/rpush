require "spec_helper"

describe Rapns::Daemon::Configuration do
  module Rails
  end

  before do
    @config = {"port" => 123, "host" => "localhost", "certificate" => "production.pem"}
  end

  it "should raise an error if the configuration file does not exist" do
    expect { Rapns::Daemon::Configuration.load("production", "/tmp/rapns-non-existant-file") }.to raise_error(Rapns::ConfigurationError, "/tmp/rapns-non-existant-file does not exist. Have you run 'rails g rapns'?")
  end

  it "should raise an error if the environment is not configured" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => {}})
    expect { Rapns::Daemon::Configuration.load("development", "/some/config.yml") }.to raise_error(Rapns::ConfigurationError, "Configuration for environment 'development' not specified in /some/config.yml")
  end

  it "should raise an error if the host is not configured" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => @config.except("host")})
    expect { Rapns::Daemon::Configuration.load("production", "/some/config.yml") }.to raise_error(Rapns::ConfigurationError, "'host' not specified for environment 'production' in /some/config.yml")
  end

  it "should raise an error if the port is not configured" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => @config.except("port")})
    expect { Rapns::Daemon::Configuration.load("production", "/some/config.yml") }.to raise_error(Rapns::ConfigurationError, "'port' not specified for environment 'production' in /some/config.yml")
  end

  it "should raise an error if the certificate is not configured" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => @config.except("certificate")})
    expect { Rapns::Daemon::Configuration.load("production", "/some/config.yml") }.to raise_error(Rapns::ConfigurationError, "'certificate' not specified for environment 'production' in /some/config.yml")
  end

  it "should set the host" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => @config})
    Rapns::Daemon::Configuration.load("production", "/some/config.yml")
    Rapns::Daemon::Configuration.host.should == "localhost"
  end

  it "should set the port" do
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => @config})
    Rapns::Daemon::Configuration.load("production", "/some/config.yml")
    Rapns::Daemon::Configuration.port.should == 123
  end

  it "should set the certificate, with absolute path" do
    Rails.stub(:root).and_return("/rails_root")
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => @config})
    Rapns::Daemon::Configuration.load("production", "/some/config.yml")
    Rapns::Daemon::Configuration.certificate.should == "/rails_root/config/rapns/production.pem"
  end

  it "should keep the absolute path of the certificate if it has one" do
    Rails.stub(:root).and_return("/rails_root")
    @config["certificate"] = "/different_path/to/production.pem"
    Rapns::Daemon::Configuration.stub(:read_config).and_return({"production" => @config})
    Rapns::Daemon::Configuration.load("production", "/some/config.yml")
    Rapns::Daemon::Configuration.certificate.should == "/different_path/to/production.pem"
  end
end