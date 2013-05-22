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

      MDM_KEY = '__rapns_mdm__'
      def mdm=(magic)
        self.attributes_for_device = (attributes_for_device || {}).merge({ MDM_KEY => magic })
      end

      CONTENT_AVAILABLE_KEY = '__rapns_content_available__'
      def content_available=(bool)
        return unless bool
        self.attributes_for_device = (attributes_for_device || {}).merge({ CONTENT_AVAILABLE_KEY => true })
      end

      def as_json
        json = ActiveSupport::OrderedHash.new

        if attributes_for_device && attributes_for_device.key?(MDM_KEY)
          json['mdm'] = attributes_for_device[MDM_KEY]
        else
          json['aps'] = ActiveSupport::OrderedHash.new
          json['aps']['alert'] = alert if alert
          json['aps']['badge'] = badge if badge
          json['aps']['sound'] = sound if sound

          if attributes_for_device && attributes_for_device[CONTENT_AVAILABLE_KEY]
            json['aps']['content-available'] = 1
          end

          if attributes_for_device
            non_aps_attributes = attributes_for_device.reject { |k, v| k == CONTENT_AVAILABLE_KEY }
            non_aps_attributes.each { |k, v| json[k.to_s] = v }
          end
        end

        json
      end

      def to_binary(options = {})
        id_for_pack = options[:for_validation] ? 0 : id
        [1, id_for_pack, expiry, 0, 32, device_token, payload_size, payload].pack("cNNccH*na*")
      end

      def data=(attrs)
        return unless attrs
        raise ArgumentError, "must be a Hash" if !attrs.is_a?(Hash)
        super attrs.merge(data || {})
      end

    end
  end
end