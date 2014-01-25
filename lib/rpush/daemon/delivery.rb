module Rpush
  module Daemon
    class Delivery
      include Reflectable

      def mark_retryable(notification, deliver_after)
        @batch.mark_retryable(notification, deliver_after)
      end

      def mark_retryable_exponential(notification)
        mark_retryable(notification, Time.now + 2 ** (notification.retries + 1))
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
