module Rpush
  module Daemon
    class Delivery
      include Reflectable
      include Loggable

      def mark_retryable(notification, deliver_after)
        if notification.fail_after && notification.fail_after < Time.now
          @batch.mark_failed(notification, nil, "Notification failed to be delivered before #{notification.fail_after.strftime("%Y-%m-%d %H:%M:%S")}.")
        else
          @batch.mark_retryable(notification, deliver_after)
        end
      end

      def mark_retryable_exponential(notification)
        mark_retryable(notification, Time.now + 2**(notification.retries + 1))
      end

      def mark_delivered
        @batch.mark_delivered(@notification)
      end

      def mark_failed(code, description)
        @batch.mark_failed(@notification, code, description)
      end
    end
  end
end
