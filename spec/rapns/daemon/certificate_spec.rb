require "spec_helper"

describe Rapns::Daemon::Certificate do

  it "should raise an error if the .pem file does not exist" do
    expect { Rapns::Daemon::Certificate.load("/tmp/rapns-missing.pem") }.to raise_error(Rapns::CertificateError, "/tmp/rapns-missing.pem does not exist. The certificate location can be configured in config/rapns/rapns.yml.")
  end

  it "should set the certificate accessor" do
    Rapns::Daemon::Certificate.stub(:read_certificate).and_return("certificate contents")
    Rapns::Daemon::Certificate.load("/dir/development.pem")
    Rapns::Daemon::Certificate.certificate.should == "certificate contents"
  end
end