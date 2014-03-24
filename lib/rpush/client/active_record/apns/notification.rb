module Rpush
  module Client
    module ActiveRecord
      module Apns
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Deprecatable

          class MultipleAppAssignmentError < StandardError; end

          validates :device_token, :presence => true
          validates :badge, :numericality => true, :allow_nil => true

          validates_with Rpush::Client::ActiveModel::Apns::DeviceTokenFormatValidator
          validates_with Rpush::Client::ActiveModel::Apns::BinaryNotificationValidator

          alias_method :attributes_for_device=, :data=
          alias_method :attributes_for_device, :data

          deprecated(:attributes_for_device, '2.1.0', 'Use :data instead.')
          deprecated(:attributes_for_device=, '2.1.0', 'Use :data instead.')

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

          MDM_KEY = '__rpush_mdm__'
          def mdm=(magic)
            self.data = (data || {}).merge({ MDM_KEY => magic })
          end

          CONTENT_AVAILABLE_KEY = '__rpush_content_available__'
          def content_available=(bool)
            return unless bool
            self.data = (data || {}).merge({ CONTENT_AVAILABLE_KEY => true })
          end

          def as_json
            json = ActiveSupport::OrderedHash.new

            if data && data.key?(MDM_KEY)
              json['mdm'] = data[MDM_KEY]
            else
              json['aps'] = ActiveSupport::OrderedHash.new
              json['aps']['alert'] = alert if alert
              json['aps']['badge'] = badge if badge
              json['aps']['sound'] = sound if sound

              if data && data[CONTENT_AVAILABLE_KEY]
                json['aps']['content-available'] = 1
              end

              if data
                non_aps_attributes = data.reject { |k, v| k == CONTENT_AVAILABLE_KEY }
                non_aps_attributes.each { |k, v| json[k.to_s] = v }
              end
            end

            json
          end

          def to_binary(options = {})
            id_for_pack = options[:for_validation] ? 0 : id
            [1, id_for_pack, expiry, 0, 32, device_token, payload_size, payload].pack("cNNccH*na*")
          end
        end
      end
    end
  end
end
