require "spec_helper"

describe Rapns::Daemon::Pem do

  it "should raise an error if the .pem file does not exist" do
    expect { Rapns::Daemon::Pem.load("development", "/tmp/rapns-missing.pem") }.to raise_error(Rapns::PemError, "/tmp/rapns-missing.pem does not exist. Your .pem file must match the Rails environment 'development'.")
  end

  it "should set the pem accessor" do
    Rapns::Daemon::Pem.stub(:read_pem).and_return("pem contents")
    Rapns::Daemon::Pem.load("development", "/dir/development.pem")
    Rapns::Daemon::Pem.pem.should == "pem contents"
  end
end