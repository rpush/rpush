require 'unit_spec_helper'

describe Rapns::App do
  it 'does not validate an app with an invalid certificate' do
    app = Rapns::Apns::App.new(:key => 'test', :environment => 'development', :certificate => 'foo')
    app.valid?
    app.errors[:certificate].should == ['Certificate value must contain a certificate and a private key.']
  end

  it 'validates a real certificate' do
    app = Rapns::Apns::App.new :key => 'test', :environment => 'development', :certificate => TEST_CERT
    app.valid?
    app.errors[:certificate].should == []
  end
end
