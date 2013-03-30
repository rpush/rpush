require 'unit_spec_helper'

describe Rapns::App do
  it 'validates the uniqueness of name within type and environment' do
    Rapns::Apns::App.create!(:name => 'test', :environment => 'production', :certificate => TEST_CERT)
    app = Rapns::Apns::App.new(:name => 'test', :environment => 'production', :certificate => TEST_CERT)
    app.valid?.should be_false
    app.errors[:name].should == ['has already been taken']

    app = Rapns::Apns::App.new(:name => 'test', :environment => 'development', :certificate => TEST_CERT)
    app.valid?.should be_true

    app = Rapns::Gcm::App.new(:name => 'test', :environment => 'production', :auth_key => TEST_CERT)
    app.valid?.should be_true
  end
end
