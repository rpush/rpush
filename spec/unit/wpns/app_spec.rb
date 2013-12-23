require 'unit_spec_helper'

describe Rapns::Wpns::App do
  subject {
    Rapns::Wpns::App.new(
      :name => 'test',
      :environment => 'development',
      :client_id => 'CLIENT_ID',
      :client_secret => 'CLIENT_SECRET'
    )
  }
  let(:existing_app) {
    Rapns::Wpns::App.create!(
      :name => 'existing',
      :environment => 'development',
      :client_id => 'CLIENT_ID',
      :client_secret => 'CLIENT_SECRET'
    )
  }

  it 'should be valid if properly instantiated' do
    subject.should be_valid
  end

  it 'should be invalid if name nil' do
    subject.name = nil
    subject.should_not be_valid
    subject.errors[:name].should == ["can't be blank"]
  end

  it 'should be invalid if name is not unique within scope' do
    subject.name = existing_app.name
    subject.should_not be_valid
    subject.errors[:name].should == ["has already been taken"]
  end
end
