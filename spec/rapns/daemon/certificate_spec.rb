require "spec_helper"

describe Rapns::Daemon::Certificate do
  it 'reads the certificate from the given path' do
    File.stub(:exists? => true)
    File.should_receive(:read).with("/dir/development.pem")
    Rapns::Daemon::Certificate.read("/dir/development.pem")
  end

  it "raises an error if the .pem file does not exist" do
    expect do
      Rapns::Daemon::Certificate.read("/tmp/rapns-missing.pem")
    end.to raise_error(Rapns::CertificateError, "/tmp/rapns-missing.pem does not exist.")
  end
end