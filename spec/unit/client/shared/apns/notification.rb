# encoding: US-ASCII
# frozen_string_literal: true

require "unit_spec_helper"

shared_examples 'Rpush::Client::Apns::Notification' do
  let(:notification) { described_class.new }
  let(:app) { Rpush::Apns::App.create!(name: 'my_app', environment: 'development', certificate: TEST_CERT) }

  it "validates the format of the device_token" do
    notification = described_class.new(device_token: "{$%^&*()}")
    expect(notification).not_to be_valid
    expect(notification.errors[:device_token]).to include("is invalid")
  end

  it "stores long alerts" do
    notification.app = app
    notification.device_token = "a" * 108
    notification.alert = "*" * 300
    expect(notification).to be_valid

    notification.save!
    notification.reload
    expect(notification.alert).to eq("*" * 300)
  end

  it "defaults the expiry to 1 day" do
    expect(notification.expiry).to eq 1.day.to_i
  end

  describe "when assigning the device token" do
    it "strips spaces from the given string" do
      notification = described_class.new(device_token: "o m g")
      expect(notification.device_token).to eq "omg"
    end

    it "strips chevrons from the given string" do
      notification = described_class.new(device_token: "<omg>")
      expect(notification.device_token).to eq "omg"
    end
  end

  describe "as_json" do
    it "includes the alert if present" do
      notification = described_class.new(alert: "hi mom")
      expect(notification.as_json["aps"]["alert"]).to eq "hi mom"
    end

    it "does not include the alert key if the alert is not present" do
      notification = described_class.new(alert: nil)
      expect(notification.as_json["aps"]).not_to be_key("alert")
    end

    it "encodes the alert as JSON if it is a Hash" do
      notification = described_class.new(alert: { 'body' => "hi mom", 'alert-loc-key' => "View" })
      expect(notification.as_json["aps"]["alert"]).to eq('body' => "hi mom", 'alert-loc-key' => "View")
    end

    it "includes the badge if present" do
      notification = described_class.new(badge: 6)
      expect(notification.as_json["aps"]["badge"]).to eq 6
    end

    it "does not include the badge key if the badge is not present" do
      notification = described_class.new(badge: nil)
      expect(notification.as_json["aps"]).not_to be_key("badge")
    end

    it "includes the sound if present" do
      notification = described_class.new(sound: "my_sound.aiff")
      expect(notification.as_json["aps"]["sound"]).to eq "my_sound.aiff"
    end

    it "does not include the sound key if the sound is not present" do
      notification = described_class.new(sound: nil)
      expect(notification.as_json["aps"]).not_to be_key("sound")
    end

    it "encodes the sound as JSON if it is a Hash" do
      notification = described_class.new(sound: { 'name' => "my_sound.aiff", 'critical' => 1, 'volume' => 0.5 })
      expect(notification.as_json["aps"]["sound"]).to eq('name' => "my_sound.aiff", 'critical' => 1, 'volume' => 0.5)
    end

    it "includes attributes for the device" do
      notification = described_class.new
      notification.data = { 'omg' => 'lol', 'wtf' => 'dunno' }
      expect(notification.as_json["omg"]).to eq "lol"
      expect(notification.as_json["wtf"]).to eq "dunno"
    end

    it "allows attributes to include a hash" do
      notification = described_class.new
      notification.data = { 'omg' => { 'ilike' => 'hashes' } }
      expect(notification.as_json["omg"]["ilike"]).to eq "hashes"
    end
  end

  describe 'MDM' do
    let(:magic) { 'abc123' }

    before do
      notification.device_token = "a" * 108
      notification.id = 1234
    end

    it 'includes the mdm magic in the payload' do
      notification.mdm = magic
      expect(notification.as_json).to eq('mdm' => magic)
    end

    it 'does not include aps attribute' do
      notification.alert = "i'm doomed"
      notification.mdm = magic
      expect(notification.as_json).not_to be_key('aps')
    end

    it 'can be converted to binary' do
      notification.mdm = magic
      expect(notification.to_binary).to be_present
    end
  end

  describe 'mutable-content' do
    it 'includes mutable-content in the payload' do
      notification.mutable_content = true
      expect(notification.as_json['aps']['mutable-content']).to eq 1
    end

    it 'does not include content-available in the payload if not set' do
      expect(notification.as_json['aps']).not_to be_key('mutable-content')
    end

    it 'does not include mutable-content as a non-aps attribute' do
      notification.mutable_content = true
      expect(notification.as_json).not_to be_key('mutable-content')
    end

    it 'does not overwrite existing attributes for the device' do
      notification.data = { 'hi' => 'mom' }
      notification.mutable_content = true
      expect(notification.as_json['aps']['mutable-content']).to eq 1
      expect(notification.as_json['hi']).to eq 'mom'
    end
  end

  describe 'content-available' do
    it 'includes content-available in the payload' do
      notification.content_available = true
      expect(notification.as_json['aps']['content-available']).to eq 1
    end

    it 'does not include content-available in the payload if not set' do
      expect(notification.as_json['aps']).not_to be_key('content-available')
    end

    it 'does not include content-available as a non-aps attribute' do
      notification.content_available = true
      expect(notification.as_json).not_to be_key('content-available')
    end

    it 'does not overwrite existing attributes for the device' do
      notification.data = { 'hi' => 'mom' }
      notification.content_available = true
      expect(notification.as_json['aps']['content-available']).to eq 1
      expect(notification.as_json['hi']).to eq 'mom'
    end
  end

  describe 'url-args' do
    it 'includes url-args in the payload' do
      notification.url_args = ['url-arg-1']
      expect(notification.as_json['aps']['url-args']).to eq ['url-arg-1']
    end

    it 'does not include url-args in the payload if not set' do
      expect(notification.as_json['aps']).not_to be_key('url-args')
    end
  end

  describe 'category' do
    it 'includes category in the payload' do
      notification.category = 'INVITE_CATEGORY'
      expect(notification.as_json['aps']['category']).to eq 'INVITE_CATEGORY'
    end

    it 'does not include category in the payload if not set' do
      expect(notification.as_json['aps']).not_to be_key('category')
    end
  end

  describe 'to_binary' do
    before do
      notification.device_token = "a" * 108
      notification.id = 1234
    end

    it 'uses APNS_PRIORITY_CONSERVE_POWER if content-available is the only key' do
      notification.alert = nil
      notification.badge = nil
      notification.sound = nil
      notification.content_available = true
      bytes = notification.to_binary.bytes.to_a[-4..]
      expect(bytes.first).to eq 5 # priority item ID
      expect(bytes.last).to eq described_class::APNS_PRIORITY_CONSERVE_POWER
    end

    it 'uses APNS_PRIORITY_IMMEDIATE if content-available is not the only key' do
      notification.alert = "New stuff!"
      notification.badge = nil
      notification.sound = nil
      notification.content_available = true
      bytes = notification.to_binary.bytes.to_a[-4..]
      expect(bytes.first).to eq 5 # priority item ID
      expect(bytes.last).to eq described_class::APNS_PRIORITY_IMMEDIATE
    end

    it "correctlies convert the notification to binary" do
      notification.sound = "1.aiff"
      notification.badge = 3
      notification.alert = "Don't panic Mr Mainwaring, don't panic!"
      notification.data = { hi: :mom }
      notification.expiry = 86_400 # 1 day
      notification.priority = described_class::APNS_PRIORITY_IMMEDIATE
      notification.app = app
      now = Time.zone.now
      allow(Time).to receive_messages(now: now)
      expect(notification.to_binary).to eq "\x02\x00\x00\x00\xAF\x01\x00 \xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\x02\x00a{\"aps\":{\"alert\":\"Don't panic Mr Mainwaring, don't panic!\",\"badge\":3,\"sound\":\"1.aiff\"},\"hi\":\"mom\"}\x03\x00\x04\x00\x00\x04\xD2\x04\x00\x04#{[now.to_i + 86_400].pack('N')}\x05\x00\x01\n"
    end
  end

  describe "bug #31" do
    it 'does not confuse a JSON looking string as JSON' do
      notification = described_class.new
      notification.alert = "{\"one\":2}"
      expect(notification.alert).to eq "{\"one\":2}"
    end
  end

  describe "bug #35" do
    it "limits payload size to 256 bytes but not the entire packet" do
      notification = described_class.new.tap do |n|
        n.device_token = "a" * 108
        n.alert = "a" * 210
        n.app = app
      end

      expect(notification.to_binary(for_validation: true).bytesize).to be > 256
      expect(notification.payload.bytesize).to be < 256
      expect(notification).to be_valid
    end
  end

  describe 'thread-id' do
    it 'includes thread-id in the payload' do
      notification.thread_id = 'THREAD-ID'
      expect(notification.as_json['aps']['thread-id']).to eq 'THREAD-ID'
    end

    it 'does not include thread-id in the payload if not set' do
      expect(notification.as_json['aps']).not_to have_key('thread-id')
    end
  end
end
