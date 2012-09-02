module Rapns
  module Apns
    class Notification < Rapns::Notification
      class MultipleAppAssignmentError < StandardError; end

      validates :device_token, :presence => true
      validates :badge, :numericality => true, :allow_nil => true

      validates_with Rapns::Apns::DeviceTokenFormatValidator
      validates_with Rapns::Apns::BinaryNotificationValidator

      alias_method :attributes_for_device=, :data=
      alias_method :attributes_for_device, :data

      def device_token=(token)
        write_attribute(:device_token, token.delete(" <>")) if !token.nil?
      end

      def alert=(alert)
        if alert.is_a?(Hash)
          write_attribute(:alert, multi_json_dump(alert))
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
            multi_json_load(string_or_json)
          else
            string_or_json
          end
        else
          multi_json_load(string_or_json) rescue string_or_json
        end
      end

      MDM_OVERIDE_KEY = '__rapns_mdm__'
      def mdm=(magic)
        self.attributes_for_device = { MDM_OVERIDE_KEY => magic }
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
        multi_json_dump(as_json)
      end

      def payload_size
        payload.bytesize
      end

      def to_binary(options = {})
        id_for_pack = options[:for_validation] ? 0 : id
        [1, id_for_pack, expiry, 0, 32, device_token, payload_size, payload].pack("cNNccH*na*")
      end
    end
  end
end