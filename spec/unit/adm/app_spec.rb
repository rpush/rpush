require 'unit_spec_helper'

describe Rapns::Adm::App do
  subject { Rapns::Adm::App.new(:name => 'test', :environment => 'development', :client_id => 'CLIENT_ID', :client_secret => 'CLIENT_SECRET') }
  let(:existing_app) { Rapns::Adm::App.create!(:name => 'existing', :environment => 'development', :client_id => 'CLIENT_ID', :client_secret => 'CLIENT_SECRET') }

  it 'should be valid if properly instantiated' do
    subject.should be_valid
  end

  it 'should be invalid if name' do
    subject.name = nil
    subject.should_not be_valid
    subject.errors[:name].should == ["can't be blank"]
  end
  
  it 'should be invalid if name is not unique within scope' do
    subject.name = existing_app.name
    subject.should_not be_valid
    subject.errors[:name].should == ["has already been taken"]
  end

  it 'should be invalid if missing client_id' do
    subject.client_id = nil
    subject.should_not be_valid
    subject.errors[:client_id].should == ["can't be blank"]
  end
  
  it 'should be invalid if missing client_secret' do
    subject.client_secret = nil
    subject.should_not be_valid
    subject.errors[:client_secret].should == ["can't be blank"]
  end
  
  describe '#access_token_expired?' do
    before(:each) do
      Timecop.freeze(Time.now)
    end

    after do
      Timecop.return
    end
    
    it 'should return true if access_token_expiration is nil' do
      subject.access_token_expired?.should be_true
    end
    
    it 'should return true if expired' do
      subject.access_token_expiration = Time.now - 5.minutes
      subject.access_token_expired?.should be_true
    end
    
    it 'should return false if not expired' do
      subject.access_token_expiration = Time.now + 5.minutes
      subject.access_token_expired?.should be_false
    end
  end
  
end
