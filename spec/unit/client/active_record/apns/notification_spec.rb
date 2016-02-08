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
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:device_token].include?("is invalid")).to be_truthy
  end

  it "should validate the length of the binary conversion of the notification" do
    notification.device_token = "a" * 64
    notification.alert = "way too long!" * 200
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:base].include?("APN notification cannot be larger than 2048 bytes. Try condensing your alert and device attributes.")).to be_truthy
  end

  it "should store long alerts" do
    notification.app = app
    notification.device_token = "a" * 64
    notification.alert = "*" * 300
    expect(notification.valid?).to be_truthy

    notification.save!
    notification.reload
    expect(notification.alert).to eq("*" * 300)
  end

  it "should default the sound to 'default'" do
    expect(notification.sound).to eq('default')
  end

  it "should default the expiry to 1 day" do
    expect(notification.expiry).to eq 1.day.to_i
  end
end if active_record?

describe Rpush::Client::ActiveRecord::Apns::Notification, "when assigning the device token" do
  it "should strip spaces from the given string" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(device_token: "o m g")
    expect(notification.device_token).to eq "omg"
  end

  it "should strip chevrons from the given string" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(device_token: "<omg>")
    expect(notification.device_token).to eq "omg"
  end
end if active_record?

describe Rpush::Client::ActiveRecord::Apns::Notification, "as_json" do
  it "should include the alert if present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: "hi mom")
    expect(notification.as_json["aps"]["alert"]).to eq "hi mom"
  end

  it "should not include the alert key if the alert is not present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: nil)
    expect(notification.as_json["aps"].key?("alert")).to be_falsey
  end

  it "should encode the alert as JSON if it is a Hash" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: { 'body' => "hi mom", 'alert-loc-key' => "View" })
    expect(notification.as_json["aps"]["alert"]).to eq('body' => "hi mom", 'alert-loc-key' => "View")
  end

  it "should include the badge if present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(badge: 6)
    expect(notification.as_json["aps"]["badge"]).to eq 6
  end

  it "should not include the badge key if the badge is not present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(badge: nil)
    expect(notification.as_json["aps"].key?("badge")).to be_falsey
  end

  it "should include the sound if present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: "my_sound.aiff")
    expect(notification.as_json["aps"]["alert"]).to eq "my_sound.aiff"
  end

  it "should not include the sound key if the sound is not present" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new(sound: nil)
    expect(notification.as_json["aps"].key?("sound")).to be_falsey
  end

  it "should include attributes for the device" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new
    notification.data = { omg: :lol, wtf: :dunno }
    expect(notification.as_json["omg"]).to eq "lol"
    expect(notification.as_json["wtf"]).to eq "dunno"
  end

  it "should allow attributes to include a hash" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new
    notification.data = { omg: { ilike: :hashes } }
    expect(notification.as_json["omg"]["ilike"]).to eq "hashes"
  end
end if active_record?

describe Rpush::Client::ActiveRecord::Apns::Notification, 'MDM' do
  let(:magic) { 'abc123' }
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.new }

  before do
    notification.device_token = "a" * 64
    notification.id = 1234
  end

  it 'includes the mdm magic in the payload' do
    notification.mdm = magic
    expect(notification.as_json).to eq('mdm' => magic)
  end

  it 'does not include aps attribute' do
    notification.alert = "i'm doomed"
    notification.mdm = magic
    expect(notification.as_json.key?('aps')).to be_falsey
  end

  it 'can be converted to binary' do
    notification.mdm = magic
    expect(notification.to_binary).to be_present
  end
end if active_record?

describe Rpush::Client::ActiveRecord::Apns::Notification, 'content-available' do
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.new }

  it 'includes content-available in the payload' do
    notification.content_available = true
    expect(notification.as_json['aps']['content-available']).to eq 1
  end

  it 'does not include content-available in the payload if not set' do
    expect(notification.as_json['aps'].key?('content-available')).to be_falsey
  end

  it 'does not include content-available as a non-aps attribute' do
    notification.content_available = true
    expect(notification.as_json.key?('content-available')).to be_falsey
  end

  it 'does not overwrite existing attributes for the device' do
    notification.data = { hi: :mom }
    notification.content_available = true
    expect(notification.as_json['aps']['content-available']).to eq 1
    expect(notification.as_json['hi']).to eq 'mom'
  end

  it 'does not overwrite the content-available flag when setting attributes for the device' do
    notification.content_available = true
    notification.data = { hi: :mom }
    expect(notification.as_json['aps']['content-available']).to eq 1
    expect(notification.as_json['hi']).to eq 'mom'
  end
end if active_record?

describe Rpush::Client::ActiveRecord::Apns::Notification, 'url-args' do
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.new }

  it 'includes url-args in the payload' do
    notification.url_args = ['url-arg-1']
    expect(notification.as_json['aps']['url-args']).to eq ['url-arg-1']
  end

  it 'does not include url-args in the payload if not set' do
    expect(notification.as_json['aps'].key?('url-args')).to be_falsey
  end
end if active_record?

describe Rpush::Client::ActiveRecord::Apns::Notification, 'category' do
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.new }

  it 'includes category in the payload' do
    notification.category = 'INVITE_CATEGORY'
    expect(notification.as_json['aps']['category']).to eq 'INVITE_CATEGORY'
  end

  it 'does not include category in the payload if not set' do
    expect(notification.as_json['aps'].key?('category')).to be_falsey
  end
end if active_record?

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
    expect(bytes.first).to eq 5 # priority item ID
    expect(bytes.last).to eq Rpush::Client::ActiveRecord::Apns::Notification::APNS_PRIORITY_CONSERVE_POWER
  end

  it 'uses APNS_PRIORITY_IMMEDIATE if content-available is not the only key' do
    notification.alert = "New stuff!"
    notification.badge = nil
    notification.sound = nil
    notification.content_available = true
    bytes = notification.to_binary.bytes.to_a[-4..-1]
    expect(bytes.first).to eq 5 # priority item ID
    expect(bytes.last).to eq Rpush::Client::ActiveRecord::Apns::Notification::APNS_PRIORITY_IMMEDIATE
  end

  it "should correctly convert the notification to binary" do
    notification.sound = "1.aiff"
    notification.badge = 3
    notification.alert = "Don't panic Mr Mainwaring, don't panic!"
    notification.data = { hi: :mom }
    notification.expiry = 86_400 # 1 day, \x00\x01Q\x80
    notification.priority = Rpush::Client::ActiveRecord::Apns::Notification::APNS_PRIORITY_IMMEDIATE
    notification.app = Rpush::Client::ActiveRecord::Apns::App.new(name: 'my_app', environment: 'development', certificate: TEST_CERT)
    expect(notification.to_binary).to eq "\x02\x00\x00\x00\x99\x01\x00 \xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\x02\x00a{\"aps\":{\"alert\":\"Don't panic Mr Mainwaring, don't panic!\",\"badge\":3,\"sound\":\"1.aiff\"},\"hi\":\"mom\"}\x03\x00\x04\x00\x00\x04\xD2\x04\x00\x04\x00\x01Q\x80\x05\x00\x01\n"
  end
end if active_record?

describe Rpush::Client::ActiveRecord::Apns::Notification, "bug #31" do
  it 'does not confuse a JSON looking string as JSON' do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new
    notification.alert = "{\"one\":2}"
    expect(notification.alert).to eq "{\"one\":2}"
  end

  it 'does confuse a JSON looking string as JSON if the alert_is_json attribute is not present' do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new
    allow(notification).to receive_messages(has_attribute?: false)
    notification.alert = "{\"one\":2}"
    expect(notification.alert).to eq('one' => 2)
  end
end if active_record?

describe Rpush::Client::ActiveRecord::Apns::Notification, "bug #35" do
  it "should limit payload size to 256 bytes but not the entire packet" do
    notification = Rpush::Client::ActiveRecord::Apns::Notification.new do |n|
      n.device_token = "a" * 64
      n.alert = "a" * 210
      n.app = Rpush::Client::ActiveRecord::Apns::App.create!(name: 'my_app', environment: 'development', certificate: TEST_CERT)
    end

    expect(notification.to_binary(for_validation: true).bytesize).to be > 256
    expect(notification.payload.bytesize).to be < 256
    expect(notification).to be_valid
  end
end if active_record?

describe Rpush::Client::ActiveRecord::Apns::Notification, "multi_json usage" do
  describe Rpush::Client::ActiveRecord::Apns::Notification, "alert" do
    it "should call MultiJson.load when multi_json version is 1.3.0" do
      notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: { a: 1 }, alert_is_json: true)
      allow(Gem).to receive(:loaded_specs).and_return('multi_json' => Gem::Specification.new('multi_json', '1.3.0'))
      expect(MultiJson).to receive(:load).with(any_args)
      notification.alert
    end

    it "should call MultiJson.decode when multi_json version is 1.2.9" do
      notification = Rpush::Client::ActiveRecord::Apns::Notification.new(alert: { a: 1 }, alert_is_json: true)
      allow(Gem).to receive(:loaded_specs).and_return('multi_json' => Gem::Specification.new('multi_json', '1.2.9'))
      expect(MultiJson).to receive(:decode).with(any_args)
      notification.alert
    end
  end
end if active_record?
