require 'unit_spec_helper'
require 'unit/notification_shared.rb'

describe Rapns::Gcm::Notification do
  it_should_behave_like 'an Notification subclass'

  let(:notification_class) { Rapns::Gcm::Notification }
  let(:notification) { notification_class.new(:auth_key => 'abc123', :app => ['test']) }
  let(:data_setter) { 'data=' }
  let(:data_getter) { 'data' }

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
end