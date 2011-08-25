module Rapns
  class Notification < ActiveRecord::Base
    set_table_name "rapns_notifications"

    validates :device_token, :presence => true, :format => { :with => /^[a-z0-9]{64}$/ }
    validates :badge, :numericality => true, :allow_nil => true

    validates_with Rapns::BinaryNotificationValidator

    scope :undelivered, lambda { where(:delivered => false) }

    def device_token=(token)
      write_attribute(:device_token, token.delete(" <>")) if !token.nil?
    end

    def sound=(value)
      if value.is_a?(TrueClass)
        write_attribute(:sound, "1.aiff")
      elsif value.is_a?(FalseClass)
        write_attribute(:sound, nil)
      else
        write_attribute(:sound, value)
      end
    end

    def attributes_for_device=(attrs)
      raise ArgumentError, "attributes_for_device must be a Hash" if !attrs.is_a?(Hash)
      write_attribute(:attributes_for_device, ActiveSupport::JSON.encode(attrs))
    end

    def attributes_for_device
      ActiveSupport::JSON.decode(read_attribute(:attributes_for_device)) if read_attribute(:attributes_for_device)
    end

    def as_json
      json = {'aps' => {}}
      json['aps']['alert'] = alert if alert
      json['aps']['badge'] = badge if badge
      json['aps']['sound'] = sound if sound
      attributes_for_device.each { |k, v| json[k.to_s] = v.to_s } if attributes_for_device
      json
    end

    # http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4
    def to_binary
      json = as_json.to_json
      [0, 0, 32, str_to_hex(device_token), 0, json.size, json].pack("ccca*cca*")
    end

    protected

    def str_to_hex(str)
      [str].pack("H*")
    end
  end
end