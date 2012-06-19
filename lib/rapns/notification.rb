module Rapns
  class Notification < ActiveRecord::Base
    self.table_name = 'rapns_notifications'

    validates :device_token, :presence => true
    validates :badge, :numericality => true, :allow_nil => true
    validates :expiry, :numericality => true, :presence => true

    validates_with Rapns::DeviceTokenFormatValidator
    validates_with Rapns::BinaryNotificationValidator

    scope :ready_for_delivery, lambda { where('delivered = ? AND failed = ? AND (deliver_after IS NULL OR deliver_after < ?)', false, false, Time.now) }

    def device_token=(token)
      write_attribute(:device_token, token.delete(" <>")) if !token.nil?
    end

    def alert=(alert)
      if alert.is_a?(Hash)
        write_attribute(:alert, ActiveSupport::JSON.encode(alert))
        self.alert_is_json = true if has_attribute?(:alert_is_json)
      else
        write_attribute(:alert, alert)
        self.alert_is_json = false if has_attribute?(:alert_is_json)
      end
    end

    def alert
      string_or_json = read_attribute(:alert)

      if has_attribute?(:alert_is_json)
        if alert_is_json?
          ActiveSupport::JSON.decode(string_or_json)
        else
          string_or_json
        end
      else
        ActiveSupport::JSON.decode(string_or_json) rescue string_or_json
      end
    end

    def attributes_for_device=(attrs)
      raise ArgumentError, "attributes_for_device must be a Hash" if !attrs.is_a?(Hash)
      write_attribute(:attributes_for_device, ActiveSupport::JSON.encode(attrs))
    end

    def attributes_for_device
      ActiveSupport::JSON.decode(read_attribute(:attributes_for_device)) if read_attribute(:attributes_for_device)
    end

    MDM_OVERIDE_KEY = '__rapns_mdm__'
    def mdm=(magic)
      self.attributes_for_device = {MDM_OVERIDE_KEY => magic}
    end

    def as_json
      json = ActiveSupport::OrderedHash.new

      if attributes_for_device && attributes_for_device.key?(MDM_OVERIDE_KEY)
        json['mdm'] = attributes_for_device[MDM_OVERIDE_KEY]
      else
        json['aps'] = ActiveSupport::OrderedHash.new
        json['aps']['alert'] = alert if alert
        json['aps']['badge'] = badge if badge
        json['aps']['sound'] = sound if sound
        attributes_for_device.each { |k, v| json[k.to_s] = v.to_s } if attributes_for_device
      end

      json
    end

    def payload
      as_json.to_json
    end

    def payload_size
      payload.bytesize
    end

    # This method conforms to the enhanced binary format.
    # http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4
    def to_binary(options = {})
      id_for_pack = options[:for_validation] ? 0 : id
      [1, id_for_pack, expiry, 0, 32, device_token, payload_size, payload].pack("cNNccH*na*")
    end
  end
end