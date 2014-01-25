require 'unit_spec_helper'

describe Rpush::App do
  it 'validates the uniqueness of name within type and environment' do
    Rpush::Apns::App.create!(:name => 'test', :environment => 'production', :certificate => TEST_CERT)
    app = Rpush::Apns::App.new(:name => 'test', :environment => 'production', :certificate => TEST_CERT)
    app.valid?.should be_false
    app.errors[:name].should eq ['has already been taken']

    app = Rpush::Apns::App.new(:name => 'test', :environment => 'development', :certificate => TEST_CERT)
    app.valid?.should be_true

    app = Rpush::Gcm::App.new(:name => 'test', :environment => 'production', :auth_key => TEST_CERT)
    app.valid?.should be_true
  end

  context 'validating certificates' do
    it 'rescues from certificate error' do
      app = Rpush::Apns::App.new(:name => 'test', :environment => 'development', :certificate => 'bad')
      expect{app.valid?}.not_to raise_error
      expect(app.valid?).to be_false
    end

    it 'raises other errors' do
      app = Rpush::Apns::App.new(:name => 'test', :environment => 'development', :certificate => 'bad')
      OpenSSL::X509::Certificate.stub(:new).and_raise(NameError, 'simulating no openssl')
      expect{app.valid?}.to raise_error(NameError)
    end
  end
end
