require "spec_helper"

describe Rapns::Daemon::Configuration do
  module Rails
  end

  before do
    @config = {"port" => 123, "host" => "localhost", "certificate" => "production.pem", "certificate_password" => "abc123", "airbrake_notify" => true}
  end

  it "should raise an error if the configuration file does not exist" do
    expect { Rapns::Daemon::Configuration.new("production", "/tmp/rapns-non-existant-file").load }.to raise_error(Rapns::ConfigurationError, "/tmp/rapns-non-existant-file does not exist. Have you run 'rails g rapns'?")
  end

  it "should raise an error if the environment is not configured" do
    configuration = Rapns::Daemon::Configuration.new("development", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => {}})
    expect { configuration.load  }.to raise_error(Rapns::ConfigurationError, "Configuration for environment 'development' not defined in /some/config.yml")
  end

  it "should raise an error if the host is not configured" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("host")})
    expect { configuration.load }.to raise_error(Rapns::ConfigurationError, "'host' not defined for environment 'production' in /some/config.yml")
  end

  it "should raise an error if the port is not configured" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("port")})
    expect { configuration.load }.to raise_error(Rapns::ConfigurationError, "'port' not defined for environment 'production' in /some/config.yml")
  end

  it "should raise an error if the certificate is not configured" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("certificate")})
    expect { configuration.load }.to raise_error(Rapns::ConfigurationError, "'certificate' not defined for environment 'production' in /some/config.yml")
  end

  it "should not raise an error if the certificate password is not configured" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("certificate_password")})
    expect { configuration.load }.should_not raise_error
  end

  it "should not raise an error if the airbrake notify flag is not configured" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("airbrake_notify")})
    expect { configuration.load }.should_not raise_error
  end

  it "should set the host" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.host.should == "localhost"
  end

  it "should set the port" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.port.should == 123
  end

  it "should set the airbrae notify flag" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.airbrake_notify?.should == true
  end

  it "should default the airbrake notify flag to false if not set" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("airbrake_notify")})
    configuration.load
    configuration.airbrake_notify?.should == false
  end

  it "should set the certificate password" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.certificate_password.should == "abc123"
  end

  it "should set the certificate password to a blank string if it is not configured" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("certificate_password")})
    configuration.load
    configuration.certificate_password.should == ""
  end

  it "should set the certificate, with absolute path" do
    Rails.stub(:root).and_return("/rails_root")
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.certificate.should == "/rails_root/config/rapns/production.pem"
  end

  it "should keep the absolute path of the certificate if it has one" do
    Rails.stub(:root).and_return("/rails_root")
    @config["certificate"] = "/different_path/to/production.pem"
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.certificate.should == "/different_path/to/production.pem"
  end
end