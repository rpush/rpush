# encoding: US-ASCII

require "unit_spec_helper"
require 'unit/notification_shared.rb'

describe Rpush::Client::ActiveRecord::Apns::Notification do
  it_should_behave_like 'an Notification subclass'

  let(:app) { Rpush::Client::ActiveRecord::Apns::App.create!(name: 'my_app', environment: 'development', certificate: TEST_CERT) }
  let(:notification_class) { Rpush::Client::ActiveRecord::Apns::Notification }
  let(:notification) { notification_class.new }

  it "should validate the format of the device_token" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(device_token: "{$%^&*()}")
    notification.valid?.should be_false
    notification.errors[:device_token].include?("is invalid").should be_true
  end

  it "should validate the length of the binary conversion of the notification" do
    notification.device_token = "a" * 64
    notification.alert = "way too long!" * 200
    notification.valid?.should be_false
    notification.errors[:base].include?("APN notification cannot be larger than 2048 bytes. Try condensing your alert and device attributes.").should be_true
  end

  it "should default the sound to 'default'" do
    notification.sound.should eq('default')
  end

  it "should default the expiry to 1 day" do
    notification.expiry.should eq 1.day.to_i
  end
end

describe Rpush::Client::ActiveRecord::Apns::Notification, "when assigning the device token" do
  it "should strip spaces from the given string" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(device_token: "o m g")
    notification.device_token.should eq "omg"
  end

  it "should strip chevrons from the given string" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(device_token: "<omg>")
    notification.device_token.should eq "omg"
  end
end

describe Rpush::Client::ActiveRecord::Apns::Notification, "as_json" do
  it "should include the alert if present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: "hi mom")
    notification.as_json["aps"]["alert"].should eq "hi mom"
  end

  it "should not include the alert key if the alert is not present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: nil)
    notification.as_json["aps"].key?("alert").should be_false
  end

  it "should encode the alert as JSON if it is a Hash" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: { 'body' => "hi mom", 'alert-loc-key' => "View" })
    notification.as_json["aps"]["alert"].should eq('body' => "hi mom", 'alert-loc-key' => "View")
  end

  it "should include the badge if present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(badge: 6)
    notification.as_json["aps"]["badge"].should eq 6
  end

  it "should not include the badge key if the badge is not present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(badge: nil)
    notification.as_json["aps"].key?("badge").should be_false
  end

  it "should include the sound if present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: "my_sound.aiff")
    notification.as_json["aps"]["alert"].should eq "my_sound.aiff"
  end

  it "should not include the sound key if the sound is not present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(sound: false)
    notification.as_json["aps"].key?("sound").should be_false
  end

  it "should include attributes for the device" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new
    notification.data = { omg: :lol, wtf: :dunno }
    notification.as_json["omg"].should eq "lol"
    notification.as_json["wtf"].should eq "dunno"
  end

  it "should allow attributes to include a hash" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new
    notification.data = { omg: { ilike: :hashes } }
    notification.as_json["omg"]["ilike"].should eq "hashes"
  end

end

describe Rpush::Client::ActiveRecord::Apns::Notification, 'MDM' do
  let(:magic) { 'abc123' }
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.new }

  it 'includes the mdm magic in the payload' do
    notification.mdm = magic
    notification.as_json.should eq('mdm' => magic)
  end

  it 'does not include aps attribute' do
    notification.alert = "i'm doomed"
    notification.mdm = magic
    notification.as_json.key?('aps').should be_false
  end
end

describe Rpush::Client::ActiveRecord::Apns::Notification, 'content-available' do
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.new }

  it 'includes content-available in the payload' do
    notification.content_available = true
    notification.as_json['aps']['content-available'].should eq 1
  end

  it 'does not include content-available in the payload if not set' do
    notification.as_json['aps'].key?('content-available').should be_false
  end

  it 'does not include content-available as a non-aps attribute' do
    notification.content_available = true
    notification.as_json.key?('content-available').should be_false
  end

  it 'does not overwrite existing attributes for the device' do
    notification.data = { hi: :mom }
    notification.content_available = true
    notification.as_json['aps']['content-available'].should eq 1
    notification.as_json['hi'].should eq 'mom'
  end

  it 'does not overwrite the content-available flag when setting attributes for the device' do
    notification.content_available = true
    notification.data = { hi: :mom }
    notification.as_json['aps']['content-available'].should eq 1
    notification.as_json['hi'].should eq 'mom'
  end
end

describe Rpush::Client::ActiveRecord::Apns::Notification, 'url-args' do
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.new }

  it 'includes url-args in the payload' do
    notification.url_args = ['url-arg-1']
    notification.as_json['aps']['url-args'].should eq ['url-arg-1']
  end

  it 'does not include url-args in the payload if not set' do
    notification.as_json['aps'].key?('url-args').should be_false
  end
end

describe Rpush::Client::ActiveRecord::Apns::Notification, 'category' do
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.new }

  it 'includes category in the payload' do
    notification.category = 'INVITE_CATEGORY'
    notification.as_json['aps']['category'].should eq 'INVITE_CATEGORY'
  end

  it 'does not include category in the payload if not set' do
    notification.as_json['aps'].key?('category').should be_false
  end
end

describe Rpush::Client::ActiveRecord::Apns::Notification, 'to_binary' do
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.new }

  before do
    notification.device_token = "a" * 64
    notification.id = 1234
  end

  it 'uses APNS_PRIORITY_CONSERVE_POWER if content-available is the only key' do
    notification.alert = nil
    notification.badge = nil
    notification.sound = nil
    notification.content_available = true
    bytes = notification.to_binary.bytes.to_a[-4..-1]
    bytes.first.should eq 5 # priority item ID
    bytes.last.should eq Rpush::Client::ActiveRecord::Apns::Notification::APNS_PRIORITY_CONSERVE_POWER
  end

  it 'uses APNS_PRIORITY_IMMEDIATE if content-available is not the only key' do
    notification.alert = "New stuff!"
    notification.badge = nil
    notification.sound = nil
    notification.content_available = true
    bytes = notification.to_binary.bytes.to_a[-4..-1]
    bytes.first.should eq 5 # priority item ID
    bytes.last.should eq Rpush::Client::ActiveRecord::Apns::Notification::APNS_PRIORITY_IMMEDIATE
  end

  it "should correctly convert the notification to binary" do
    notification.sound = "1.aiff"
    notification.badge = 3
    notification.alert = "Don't panic Mr Mainwaring, don't panic!"
    notification.data = { hi: :mom }
    notification.expiry = 86_400 # 1 day, \x00\x01Q\x80
    notification.priority = Rpush::Client::ActiveRecord::Apns::Notification::APNS_PRIORITY_IMMEDIATE
    notification.app = Rpush::Client::ActiveRecord::Apns::App.new(name: 'my_app', environment: 'development', certificate: TEST_CERT)
    notification.to_binary.should eq "\x02\x00\x00\x00\x99\x01\x00 \xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\x02\x00a{\"aps\":{\"alert\":\"Don't panic Mr Mainwaring, don't panic!\",\"badge\":3,\"sound\":\"1.aiff\"},\"hi\":\"mom\"}\x03\x00\x04\x00\x00\x04\xD2\x04\x00\x04\x00\x01Q\x80\x05\x00\x01\n"
  end
end

describe Rpush::Client::ActiveRecord::Apns::Notification, "bug #31" do
  it 'does not confuse a JSON looking string as JSON' do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new
    notification.alert = "{\"one\":2}"
    notification.alert.should eq "{\"one\":2}"
  end

  it 'does confuse a JSON looking string as JSON if the alert_is_json attribute is not present' do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new
    notification.stub(:has_attribute? => false)
    notification.alert = "{\"one\":2}"
    notification.alert.should eq('one' => 2)
  end
end

describe Rpush::Client::ActiveRecord::Apns::Notification, "bug #35" do
  it "should limit payload size to 256 bytes but not the entire packet" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new do |n|
      n.device_token = "a" * 64
      n.alert = "a" * 210
      n.app = Rpush::Client::ActiveRecord::Apns::App.create!(name: 'my_app', environment: 'development', certificate: TEST_CERT)
    end

    notification.to_binary(for_validation: true).bytesize.should be > 256
    notification.payload.bytesize.should be < 256
    notification.should be_valid
  end
end

describe Rpush::Client::ActiveRecord::Apns::Notification, "multi_json usage" do
  describe Rpush::Client::ActiveRecord::Apns::Notification, "alert" do
    it "should call MultiJson.load when multi_json version is 1.3.0" do
      notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: { a: 1 }, alert_is_json: true)
      Gem.stub(:loaded_specs).and_return('multi_json' => Gem::Specification.new('multi_json', '1.3.0'))
      MultiJson.should_receive(:load).with(any_args)
      notification.alert
    end

    it "should call MultiJson.decode when multi_json version is 1.2.9" do
      notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: { a: 1 }, alert_is_json: true)
      Gem.stub(:loaded_specs).and_return('multi_json' => Gem::Specification.new('multi_json', '1.2.9'))
      MultiJson.should_receive(:decode).with(any_args)
      notification.alert
    end
  end
end
