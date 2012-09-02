require "unit_spec_helper"

describe Rapns::App do
  it { should validate_numericality_of(:connections) }

  it 'validates the uniqueness of name within type and environment' do
    Rapns::Apns::App.create!(:name => 'test', :environment => 'production', :certificate => '0x0')
    app = Rapns::Apns::App.new(:name => 'test', :environment => 'production', :certificate => '0x0')
    app.valid?.should be_false
    app.errors[:name].should == ['has already been taken']

    app = Rapns::Apns::App.new(:name => 'test', :environment => 'development', :certificate => '0x0')
    app.valid?.should be_true

    app = Rapns::Gcm::App.new(:name => 'test', :environment => 'production', :auth_key => 'abc123')
    app.valid?.should be_true
  end
end
