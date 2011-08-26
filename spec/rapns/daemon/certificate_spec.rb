require "spec_helper"

describe Rapns::Daemon::Certificate do

  it "should raise an error if the .pem file does not exist" do
    cert = Rapns::Daemon::Certificate.new("/tmp/rapns-missing.pem")
    expect { cert.load }.to raise_error(Rapns::CertificateError, "/tmp/rapns-missing.pem does not exist. The certificate location can be configured in config/rapns/rapns.yml.")
  end

  it "should set the certificate accessor" do
    cert = Rapns::Daemon::Certificate.new("/dir/development.pem")
    cert.stub(:read_certificate).and_return("certificate contents")
    cert.load
    cert.certificate.should == "certificate contents"
  end
end