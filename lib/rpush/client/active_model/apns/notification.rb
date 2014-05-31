module Rpush
  module Client
    module ActiveModel
      module Apns
        module Notification
          def self.included(base)
            base.instance_eval do
              validates :device_token, presence: true
              validates :badge, numericality: true, allow_nil: true

              validates_with Rpush::Client::ActiveModel::Apns::DeviceTokenFormatValidator
              validates_with Rpush::Client::ActiveModel::Apns::BinaryNotificationValidator
            end
          end

          def device_token=(token)
            write_attribute(:device_token, token.delete(" <>")) unless token.nil?
          end

          MDM_KEY = '__rpush_mdm__'
          def mdm=(magic)
            self.data = (data || {}).merge(MDM_KEY => magic)
          end

          CONTENT_AVAILABLE_KEY = '__rpush_content_available__'
          def content_available=(bool)
            return unless bool
            self.data = (data || {}).merge(CONTENT_AVAILABLE_KEY => true)
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
                non_aps_attributes = data.reject { |k, _| k == CONTENT_AVAILABLE_KEY }
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
