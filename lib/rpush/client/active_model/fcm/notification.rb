module Rpush
  module Client
    module ActiveModel
      module Fcm
        module Notification
          FCM_PRIORITY_HIGH = Rpush::Client::ActiveModel::Apns::Notification::APNS_PRIORITY_IMMEDIATE
          FCM_PRIORITY_NORMAL = Rpush::Client::ActiveModel::Apns::Notification::APNS_PRIORITY_CONSERVE_POWER
          FCM_PRIORITIES = [FCM_PRIORITY_HIGH, FCM_PRIORITY_NORMAL]

          ROOT_NOTIFICATION_KEYS = %w[title body image].freeze
          ANDROID_NOTIFICATION_KEYS = %w[icon tag color click_action body_loc_key body_loc_args title_loc_key
                                         title_loc_args channel_id ticker sticky event_time local_only
                                         default_vibrate_timings default_light_settings vibrate_timings
                                         visibility notification_count light_settings].freeze

          def self.included(base)
            base.instance_eval do
              validates :device_token, presence: true
              validates :priority, inclusion: { in: FCM_PRIORITIES }, allow_nil: true

              validates_with Rpush::Client::ActiveModel::PayloadDataSizeValidator, limit: 4096
              validates_with Rpush::Client::ActiveModel::RegistrationIdsCountValidator, limit: 1000

              validates_with Rpush::Client::ActiveModel::Fcm::ExpiryCollapseKeyMutualInclusionValidator
              validates_with Rpush::Client::ActiveModel::Fcm::NotificationKeysInAllowedListValidator
            end
          end

          def payload_data_size
            multi_json_dump(as_json['message']['data']).bytesize
          end

          # This is a hack. The schema defines `priority` to be an integer, but FCM expects a string.
          # But for users of rpush to have an API they might expect (setting priority to `high`, not 10)
          # we do a little conversion here.
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

          def dry_run=(value)
            fail ArgumentError, 'FCM does not support dry run' if value
          end

          def as_json(options = nil) # rubocop:disable Metrics/PerceivedComplexity
            json = {
              'data' => data,
              'android' => android_config,
              'apns' => apns_config,
              'token' => device_token
            }

            json['notification'] = root_notification if notification
            { 'message' => json }
          end

          def android_config
            json = ActiveSupport::OrderedHash.new
            json['notification'] = android_notification if notification
            json['collapse_key'] = collapse_key if collapse_key
            json['priority'] = priority_str if priority
            json['ttl'] = "#{expiry}s" if expiry
            json
          end

          def apns_config
            json = ActiveSupport::OrderedHash.new
            json['payload'] = ActiveSupport::OrderedHash.new

            aps = ActiveSupport::OrderedHash.new
            aps['mutable-content'] = 1 if mutable_content
            aps['content-available'] = 1 if content_available
            aps['sound'] = 'default' if sound == 'default'

            json['payload']['aps'] = aps

            json
          end

          def notification=(value)
            value = value.with_indifferent_access if value.is_a?(Hash)
            super(value)
          end

          def root_notification
            return {} unless notification

            notification.slice(*ROOT_NOTIFICATION_KEYS)
          end

          def android_notification
            json = notification&.slice(*ANDROID_NOTIFICATION_KEYS) || {}
            json['notification_priority'] = priority_for_notification if priority
            json['sound'] = sound if sound
            json['default_sound'] = sound == 'default' ? true : false
            json
          end

          def priority_str
            case
            when priority <= 5 then 'normal'
            else
              'high'
            end
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
