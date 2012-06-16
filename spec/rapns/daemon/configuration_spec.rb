require "spec_helper"

describe Rapns::Daemon::Configuration do
  module Rails
  end

  let(:config) do
    {
      "airbrake_notify" => false,
      "pid_file" => "rapns.pid",
      "push" => {
        "poll" => 4
      },
      "feedback" => {
        "poll" => 30
      }
    }
  end

  let(:configuration) { Rapns::Daemon::Configuration.load("production", "/some/config.yml") }

  before do
    File.stub(:exists? => true)
    File.stub(:open => {"production" => config})
    Rails.stub(:root).and_return("/rails_root")
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

  it "sets the airbrake notify flag" do
    configuration.airbrake_notify.should == false
  end

  it "defaults the airbrake notify flag to true if not set" do
    config.delete('airbrake_notify')
    configuration.airbrake_notify.should == true
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

  it 'sets check_for_errors' do
    config['check_for_errors'] = false
    configuration.check_for_errors.should be_false
  end

  it 'sets check_for_errors to true by default' do
    config.delete('check_for_errors')
    configuration.check_for_errors.should be_true
  end

  it 'sets feeder_batch_size' do
    config['feeder_batch_size'] = 1000
    configuration.feeder_batch_size.should == 1000
  end

  it 'sets feeder_batch_size to 5000 by default' do
    config.delete('feeder_batch_size')
    configuration.feeder_batch_size.should == 5000
  end
end
