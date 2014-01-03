require 'unit_spec_helper'
require 'unit/notification_shared.rb'

describe Rapns::Wpns::Notification do
  it_should_behave_like 'an Notification subclass'
  let(:app) { Rapns::Wpns::App.create!(:name => 'test', :auth_key => 'abc') }
  let(:notification_class) { Rapns::Wpns::Notification }
  let(:notification) { notification_class.new }
  let(:data_setter) { 'data=' }
  let(:data_getter) { 'data' }

  it "should have an url in the uri parameter" do
    notification = Rapns::Wpns::Notification.new(:alert =>"abc", :uri => "somthing")
    notification.valid?.should be_false
    notification.errors[:uri].include?("is invalid").should be_true
  end

  it "should be invalid if there's no message" do
    notification = Rapns::Wpns::Notification.new(:alert => "", :uri => "http://meh.com/something/else")
    notification.valid?.should be_false
    notification.errors[:base].include?("WP notification cannot have an empty body").should be_true
  end
end

describe Rapns::Wpns::Notification, "when assigning the url" do
  it "should be a valid url" do
    notification = Rapns::Wpns::Notification.new(:alert => "abc", :uri => "some")
    notification.uri_is_valid?.should be_false
  end
end
