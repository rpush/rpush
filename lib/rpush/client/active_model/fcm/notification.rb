module Rpush
  module Client
    module ActiveModel
      module Fcm
        module Notification
          FCM_PRIORITY_HIGH = Rpush::Client::ActiveModel::Apns::Notification::APNS_PRIORITY_IMMEDIATE
          FCM_PRIORITY_NORMAL = Rpush::Client::ActiveModel::Apns::Notification::APNS_PRIORITY_CONSERVE_POWER
          FCM_PRIORITIES = [FCM_PRIORITY_HIGH, FCM_PRIORITY_NORMAL]

          def self.included(base)
            base.instance_eval do
              validates :device_token, presence: true
              validates :priority, inclusion: { in: FCM_PRIORITIES }, allow_nil: true

              validates_with Rpush::Client::ActiveModel::PayloadDataSizeValidator, limit: 4096
              validates_with Rpush::Client::ActiveModel::RegistrationIdsCountValidator, limit: 1000

              validates_with Rpush::Client::ActiveModel::Fcm::ExpiryCollapseKeyMutualInclusionValidator
            end
          end

          # This is a hack. The schema defines `priority` to be an integer, but FCM expects a string.
          # But for users of rpush to have an API they might expect (setting priority to `high`, not 10)
          # we do a little conversion here.
          # I'm not happy about it, but this will have to do until I can take a further look.
          def priority=(priority)
            case priority
              when 'high', FCM_PRIORITY_HIGH
                super(FCM_PRIORITY_HIGH)
              when 'normal', FCM_PRIORITY_NORMAL
                super(FCM_PRIORITY_NORMAL)
              else
                errors.add(:priority, 'must be one of either "normal" or "high"')
            end
          end

          def as_json(options = nil) # rubocop:disable Metrics/PerceivedComplexity
            json = {
              'data' => data,
              'android' => android_config,
              'token' => device_token
            }
            json['content_available'] = content_available if content_available
            json['notification'] = notification if notification
            { 'message' => json }
          end

          def android_config
            json = {
              'notification' => android_notification
            }
            json['collapse_key'] = collapse_key if collapse_key
            json['priority'] = priority if priority
            json['ttl'] = "#{expiry}s" if expiry
            json
          end

          def android_notification
            json = notification || {}
            json['notification_priority'] = priority_for_notification if priority
            json['default_sound'] = sound if sound
            json
          end

          def priority_for_notification
            case priority
            when 0 then 'PRIORITY_UNSPECIFIED'
            when 1 then 'PRIORITY_MIN'
            when 2 then 'PRIORITY_LOW'
            when 5 then 'PRIORITY_DEFAULT'
            when 6 then 'PRIORITY_HIGH'
            when 10 then 'PRIORITY_MAX'
            else
              'PRIORITY_DEFAULT'
            end
          end
        end
      end
    end
  end
end