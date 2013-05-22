# encoding: US-ASCII

require "unit_spec_helper"
require 'unit/notification_shared.rb'

describe Rapns::Apns::Notification do
  it_should_behave_like 'an Notification subclass'

  let(:notification_class) { Rapns::Apns::Notification }
  let(:notification) { notification_class.new }
  let(:data_setter) { 'attributes_for_device=' }
  let(:data_getter) { 'attributes_for_device' }

  it "should validate the format of the device_token" do
    notification = Rapns::Apns::Notification.new(:device_token => "{$%^&*()}")
    notification.valid?.should be_false
    notification.errors[:device_token].include?("is invalid").should be_true
  end

  it "should validate the length of the binary conversion of the notification" do
    notification.device_token = "a" * 64
    notification.alert = "way too long!" * 100
    notification.valid?.should be_false
    notification.errors[:base].include?("APN notification cannot be larger than 256 bytes. Try condensing your alert and device attributes.").should be_true
  end

  it "should default the sound to 'default'" do
    notification.sound.should eq('default')
  end

  it "should default the expiry to 1 day" do
    notification.expiry.should == 1.day.to_i
  end
end

describe Rapns::Apns::Notification, "when assigning the device token" do
  it "should strip spaces from the given string" do
    notification = Rapns::Apns::Notification.new(:device_token => "o m g")
    notification.device_token.should == "omg"
  end

  it "should strip chevrons from the given string" do
    notification = Rapns::Apns::Notification.new(:device_token => "<omg>")
    notification.device_token.should == "omg"
  end
end

describe Rapns::Apns::Notification, "as_json" do
  it "should include the alert if present" do
    notification = Rapns::Apns::Notification.new(:alert => "hi mom")
    notification.as_json["aps"]["alert"].should == "hi mom"
  end

  it "should not include the alert key if the alert is not present" do
    notification = Rapns::Apns::Notification.new(:alert => nil)
    notification.as_json["aps"].key?("alert").should be_false
  end

  it "should encode the alert as JSON if it is a Hash" do
    notification = Rapns::Apns::Notification.new(:alert => { 'body' => "hi mom", 'alert-loc-key' => "View" })
    notification.as_json["aps"]["alert"].should == { 'body' => "hi mom", 'alert-loc-key' => "View" }
  end

  it "should include the badge if present" do
    notification = Rapns::Apns::Notification.new(:badge => 6)
    notification.as_json["aps"]["badge"].should == 6
  end

  it "should not include the badge key if the badge is not present" do
    notification = Rapns::Apns::Notification.new(:badge => nil)
    notification.as_json["aps"].key?("badge").should be_false
  end

  it "should include the sound if present" do
    notification = Rapns::Apns::Notification.new(:alert => "my_sound.aiff")
    notification.as_json["aps"]["alert"].should == "my_sound.aiff"
  end

  it "should not include the sound key if the sound is not present" do
    notification = Rapns::Apns::Notification.new(:sound => false)
    notification.as_json["aps"].key?("sound").should be_false
  end

  it "should include attributes for the device" do
    notification = Rapns::Apns::Notification.new
    notification.attributes_for_device = {:omg => :lol, :wtf => :dunno}
    notification.as_json["omg"].should == "lol"
    notification.as_json["wtf"].should == "dunno"
  end

  it "should allow attributes to include a hash" do
    notification = Rapns::Apns::Notification.new
    notification.attributes_for_device = {:omg => {:ilike => :hashes}}
    notification.as_json["omg"]["ilike"].should == "hashes"
  end

end

describe Rapns::Apns::Notification, 'MDM' do
  let(:magic) { 'abc123' }
  let(:notification) { Rapns::Apns::Notification.new }

  it 'includes the mdm magic in the payload' do
    notification.mdm = magic
    notification.as_json.should == {'mdm' => magic}
  end

  it 'does not include aps attribute' do
    notification.alert = "i'm doomed"
    notification.mdm = magic
    notification.as_json.key?('aps').should be_false
  end
end

describe Rapns::Apns::Notification, 'content-available' do
  let(:notification) { Rapns::Apns::Notification.new }

  it 'includes content-available in the payload' do
    notification.content_available = true
    notification.as_json['aps']['content-available'].should == 1
  end

  it 'does not include content-available in the payload if not set' do
    notification.as_json['aps'].key?('content-available').should be_false
  end

  it 'does not include content-available as a non-aps attribute' do
    notification.content_available = true
    notification.as_json.key?('content-available').should be_false
  end

  it 'does not overwrite existing attributes for the device' do
    notification.data = {:hi => :mom}
    notification.content_available = true
    notification.as_json['aps']['content-available'].should == 1
    notification.as_json['hi'].should == 'mom'
  end

  it 'does not overwrite the content-available flag when setting attributes for the device' do
    notification.content_available = true
    notification.data = {:hi => :mom}
    notification.as_json['aps']['content-available'].should == 1
    notification.as_json['hi'].should == 'mom'
  end

end

describe Rapns::Apns::Notification, "to_binary" do
  it "should correctly convert the notification to binary" do
    notification = Rapns::Apns::Notification.new
    notification.device_token = "a" * 64
    notification.sound = "1.aiff"
    notification.badge = 3
    notification.alert = "Don't panic Mr Mainwaring, don't panic!"
    notification.attributes_for_device = {:hi => :mom}
    notification.expiry = 86400 # 1 day, \x00\x01Q\x80
    notification.app = Rapns::Apns::App.create!(:name => 'my_app', :environment => 'development', :certificate => TEST_CERT)
    notification.save!
    notification.stub(:id).and_return(1234)
    notification.to_binary.should == "\x01\x00\x00\x04\xD2\x00\x01Q\x80\x00 \xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\x00a{\"aps\":{\"alert\":\"Don't panic Mr Mainwaring, don't panic!\",\"badge\":3,\"sound\":\"1.aiff\"},\"hi\":\"mom\"}"
  end
end

describe Rapns::Apns::Notification, "bug #31" do
  it 'does not confuse a JSON looking string as JSON' do
    notification = Rapns::Apns::Notification.new
    notification.alert = "{\"one\":2}"
    notification.alert.should == "{\"one\":2}"
  end

  it 'does confuse a JSON looking string as JSON if the alert_is_json attribute is not present' do
    notification = Rapns::Apns::Notification.new
    notification.stub(:has_attribute? => false)
    notification.alert = "{\"one\":2}"
    notification.alert.should == {"one" => 2}
  end
end

describe Rapns::Apns::Notification, "bug #35" do
  it "should limit payload size to 256 bytes but not the entire packet" do
    notification = Rapns::Apns::Notification.new do |n|
      n.device_token = "a" * 64
      n.alert = "a" * 210
      n.app = Rapns::Apns::App.create!(:name => 'my_app', :environment => 'development', :certificate => TEST_CERT)
    end

    notification.to_binary(:for_validation => true).bytesize.should > 256
    notification.payload_size.should < 256
    notification.should be_valid
  end
end

describe Rapns::Apns::Notification, "multi_json usage" do
  describe Rapns::Apns::Notification, "alert" do
    it "should call MultiJson.load when multi_json version is 1.3.0" do
      notification = Rapns::Apns::Notification.new(:alert => { :a => 1 }, :alert_is_json => true)
      Gem.stub(:loaded_specs).and_return( { 'multi_json' => Gem::Specification.new('multi_json', '1.3.0') } )
      MultiJson.should_receive(:load).with(any_args())
      notification.alert
    end

    it "should call MultiJson.decode when multi_json version is 1.2.9" do
      notification = Rapns::Apns::Notification.new(:alert => { :a => 1 }, :alert_is_json => true)
      Gem.stub(:loaded_specs).and_return( { 'multi_json' => Gem::Specification.new('multi_json', '1.2.9') } )
      MultiJson.should_receive(:decode).with(any_args())
      notification.alert
    end
  end
end
