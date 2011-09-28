require "spec_helper"

describe Rapns::Daemon::Configuration do
  module Rails
  end

  before do
    Rails.stub(:root).and_return("/rails_root")
    @config = {"port" => 123, "host" => "localhost", "certificate" => "production.pem", "certificate_password" => "abc123", "airbrake_notify" => false, "poll" => 4, "connections" => 6, "pid_file" => "rapns.pid"}
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

  it "should set the airbrake notify flag" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.airbrake_notify?.should == false
  end

  it "should default the airbrake notify flag to true if not set" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("airbrake_notify")})
    configuration.load
    configuration.airbrake_notify?.should == true
  end

  it "should set the poll frequency" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.poll.should == 4
  end

  it "should default the poll frequency to 2 if not set" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("poll")})
    configuration.load
    configuration.poll.should == 2
  end

  it "should set the number of connections" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.connections.should == 6
  end

  it "should default the number of connections to 3 if not set" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config.except("connections")})
    configuration.load
    configuration.connections.should == 3
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
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.certificate.should == "/rails_root/config/rapns/production.pem"
  end

  it "should keep the absolute path of the certificate if it has one" do
    @config["certificate"] = "/different_path/to/production.pem"
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.certificate.should == "/different_path/to/production.pem"
  end

  it "should set the PID file path" do
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.pid_file.should == "/rails_root/rapns.pid"
  end

  it "should keep the absolute path of the PID file if it has one" do
    @config["pid_file"] = "/some/absolue/path/rapns.pid"
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.pid_file.should == "/some/absolue/path/rapns.pid"
  end

  it "should return nil if no PID file was set" do
    @config["pid_file"] = ""
    configuration = Rapns::Daemon::Configuration.new("production", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => @config})
    configuration.load
    configuration.pid_file.should be_nil
  end
end