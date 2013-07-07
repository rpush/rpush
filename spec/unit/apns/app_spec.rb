require 'unit_spec_helper'

describe Rapns::App do
  it 'does not validate an app with an invalid certificate' do
    app = Rapns::Apns::App.new(:name => 'test', :environment => 'development', :certificate => 'foo')
    app.valid?
    app.errors[:certificate].should == ['Certificate value must contain a certificate and a private key.']
  end

  it 'validates a certificate without a password' do
    app = Rapns::Apns::App.new :name => 'test', :environment => 'development', :certificate => TEST_CERT
    app.valid?
    app.errors[:certificate].should == []
  end

  it 'validates a certificate with a password' do
    app = Rapns::Apns::App.new :name => 'test', :environment => 'development',
      :certificate => TEST_CERT_WITH_PASSWORD, :password => 'fubar'
    app.valid?
    app.errors[:certificate].should == []
  end

  it 'validates a certificate with an incorrect password' do
    app = Rapns::Apns::App.new :name => 'test', :environment => 'development',
      :certificate => TEST_CERT_WITH_PASSWORD, :password => 'incorrect'
    app.valid?
    app.errors[:certificate].should == ["Certificate value must contain a certificate and a private key."]
  end
end
