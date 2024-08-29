module Rpush
  module Client
    module ActiveModel
      module Fcm
        class NotificationKeysInAllowedListValidator < ::ActiveModel::Validator
          def validate(record)
            return unless record.notification

            allowed_keys = Notification::ROOT_NOTIFICATION_KEYS + Notification::ANDROID_NOTIFICATION_KEYS
            invalid_keys = record.notification.keys - allowed_keys

            return if invalid_keys.empty?

            record.errors.add(:notification, "contains invalid keys: #{invalid_keys.join(', ')}")
          end
        end
      end
    end
  end
end
