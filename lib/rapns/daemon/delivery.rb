module Rapns
  module Daemon
    class Delivery
      include Reflectable

      def mark_retryable(notification, deliver_after)
        @batch.mark_retryable(notification, deliver_after)
        reflect(:notification_will_retry, notification)
      end

      def mark_retryable_exponential(notification)
        mark_retryable(notification, Time.now + 2 ** (notification.retries + 1))
      end

      def mark_delivered
        @batch.mark_delivered(@notification)
        reflect(:notification_delivered, @notification)
      end

      def mark_failed(code, description)
        @batch.mark_failed(@notification, code, description)
        reflect(:notification_failed, @notification)
      end
    end
  end
end
