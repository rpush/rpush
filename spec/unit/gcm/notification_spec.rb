require 'unit_spec_helper'

describe Rapns::Gcm::Notification do
  let(:notification) { Rapns::Gcm::Notification.new(:auth_key => 'abc123', :app => ['test']) }

  it { should validate_presence_of :auth_key }

  it 'allows multiple apps to be assigned' do
    notification.app = ['app1', 'app']
    notification.save!
    notification.app.should == ['app1', 'app']
  end

  it 'transparently converts a app name String into an Array' do
    notification.app = 'foo'
    notification.save!
    notification.app.should == ['foo']
  end

  it 'validates that data and collapse_key are mutually exclusive' do
    notification.collapse_key = 'foo'
    notification.data = { :foo => :bar }
    notification.valid?.should be_false
    notification.errors[:base].should == ['collapse_key and data cannot both be set.']
  end
end