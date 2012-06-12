require "spec_helper"

describe Rapns::Daemon::Configuration do
  module Rails
  end

  let(:config) do
    {
      "airbrake_notify" => false,
      "pid_file" => "rapns.pid",
      "push" => {
        "port" => 123,
        "host" => "localhost",
        "poll" => 4,
      },
      "feedback" => {
        "port" => 123,
        "host" => "localhost",
        "poll" => 30,
      },
      "myapp" => {
        "certificate" => "myapp.pem",
        "certificate_password" => "myapppass",
        "connections" => 8
      }
    }
  end

  let(:configuration) { Rapns::Daemon::Configuration.load("production", "/some/config.yml") }

  before do
    File.stub(:exists? => true)
    File.stub(:open => {"production" => config})
    Rails.stub(:root).and_return("/rails_root")
    Rapns::Daemon::Certificate.stub(:read)
  end

  it 'opens the config from the given path' do
    YAML.stub(:load => {"production" => config})
    fd = stub(:read => nil)
    File.should_receive(:open).with("/tmp/rapns-non-existant-file").and_yield(fd)
    config = Rapns::Daemon::Configuration.new("production", "/tmp/rapns-non-existant-file")
    config.stub(:ensure_config_exists)
    config.load
  end

  it 'reads the config as YAML' do
    YAML.should_receive(:load).and_return({"production" => config})
    fd = stub(:read => nil)
    File.stub(:open).and_yield(fd)
    config = Rapns::Daemon::Configuration.new("production", "/tmp/rapns-non-existant-file")
    config.stub(:ensure_config_exists)
    config.load
  end

  it "raises an error if the configuration file does not exist" do
    File.stub(:exists? => false)
    expect { Rapns::Daemon::Configuration.new("production", "/tmp/rapns-non-existant-file").load }.to raise_error(Rapns::ConfigurationError, "/tmp/rapns-non-existant-file does not exist. Have you run 'rails g rapns'?")
  end

  it "raises an error if the environment is not configured" do
    configuration = Rapns::Daemon::Configuration.new("development", "/some/config.yml")
    configuration.stub(:read_config).and_return({"production" => {}})
    expect { configuration.load }.to raise_error(Rapns::ConfigurationError, "Configuration for environment 'development' not defined in /some/config.yml")
  end

  it "raises an error if the push host is not configured" do
    config["push"]["host"] = nil
    expect { configuration }.to raise_error(Rapns::ConfigurationError, "'push.host' not defined for environment 'production' in /some/config.yml. You may need to run 'rails g rapns' after updating.")
  end

  it "raises an error if the push port is not configured" do
    config["push"]["port"] = nil
    expect { configuration }.to raise_error(Rapns::ConfigurationError, "'push.port' not defined for environment 'production' in /some/config.yml. You may need to run 'rails g rapns' after updating.")
  end

  it "raises an error if the feedback host is not configured" do
    config["feedback"]["host"] = nil
    expect { configuration }.to raise_error(Rapns::ConfigurationError, "'feedback.host' not defined for environment 'production' in /some/config.yml. You may need to run 'rails g rapns' after updating.")
  end

  it "raises an error if the feedback port is not configured" do
    config["feedback"]["port"] = nil
    expect { configuration }.to raise_error(Rapns::ConfigurationError, "'feedback.port' not defined for environment 'production' in /some/config.yml. You may need to run 'rails g rapns' after updating.")
  end

  it "sets the push host" do
    configuration.push.host.should == "localhost"
  end

  it "sets the push port" do
    configuration.push.port.should == 123
  end

  it "sets the feedback port" do
    configuration.feedback.port.should == 123
  end

  it "sets the feedback host" do
    configuration.feedback.host.should == "localhost"
  end

  it "sets the airbrake notify flag" do
    configuration.airbrake_notify?.should == false
  end

  it "defaults the airbrake notify flag to true if not set" do
    config.delete('airbrake_notify')
    configuration.airbrake_notify?.should == true
  end

  it "sets the push poll frequency" do
    configuration.push.poll.should == 4
  end

  it "sets the feedback poll frequency" do
    configuration.feedback.poll.should == 30
  end

  it "defaults the push poll frequency to 2 if not set" do
    config["push"]["poll"] = nil
    configuration.push.poll.should == 2
  end

  it "defaults the feedback poll frequency to 60 if not set" do
    config["feedback"]["poll"] = nil
    configuration.feedback.poll.should == 60
  end

  it "sets the PID file path" do
    configuration.pid_file.should == "/rails_root/rapns.pid"
  end

  it "keeps the absolute path of the PID file if it has one" do
    config["pid_file"] = "/some/absolue/path/rapns.pid"
    configuration.pid_file.should == "/some/absolue/path/rapns.pid"
  end

  it "returns nil if no PID file was set" do
    config["pid_file"] = ""
    configuration.pid_file.should be_nil
  end

  describe "App specific configuration" do
    it 'raises an error if no applications are configured' do
      config.delete('myapp')
      expect { configuration }.should raise_error(Rapns::ConfigurationError)
    end

    it "sets the certificate password" do
      configuration.apps['myapp'].certificate_password.should == "myapppass"
    end

    it "sets the certificate password to a blank string if it is not configured" do
      config['myapp'].delete('certificate_password')
      configuration.apps['myapp'].certificate_password.should == ""
    end

    it "reads the certificate, with absolute path" do
      Rapns::Daemon::Certificate.should_receive(:read).with('/rails_root/config/rapns/myapp.pem')
      configuration
    end

    it 'sets the certificate contents' do
      Rapns::Daemon::Certificate.stub(:read => 'ima cert')
      configuration.apps['myapp'].certificate.should == 'ima cert'
    end

    it "reads the absolute path of the certificate" do
      config['myapp']["certificate"] = '/different_path/to/myapp.pem'
      Rapns::Daemon::Certificate.should_receive(:read).with('/different_path/to/myapp.pem')
      configuration
    end

    it 'sets the number of connections for the app' do
      configuration.apps['myapp'].connections.should == 8
    end

    it "defaults the number of push connections to 3 if not set" do
      config["myapp"]["connections"] = nil
      configuration.apps['myapp'].connections.should == 3
    end

    it "raises an error if the certificate is not configured" do
      config['myapp']['certificate'] = nil
      expect { configuration }.to raise_error(Rapns::ConfigurationError, "'myapp.certificate' not defined for environment 'production' in /some/config.yml. You may need to run 'rails g rapns' after updating.")
    end
  end
end
