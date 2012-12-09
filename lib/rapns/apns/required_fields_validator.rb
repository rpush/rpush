module Rapns
  module Apns
    class RequiredFieldsValidator < ActiveModel::Validator

      # Notifications must contain one of alert, badge or sound as per:
      # https://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ApplePushService/ApplePushService.html
      def validate(record)
        if record.alert.nil? && record.badge.nil? && record.sound.nil?
          record.errors[:base] << "APN Notification must contain one of alert, badge, or sound"
        end
      end
    end
  end
end