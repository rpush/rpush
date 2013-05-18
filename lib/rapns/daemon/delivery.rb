module Rapns
  module Daemon
    class Delivery
      include Reflectable

      def self.perform(*args)
        new(*args).perform
      end

      def retry_after(notification, deliver_after)
        Rapns::Daemon.store.retry_after(notification, deliver_after)
        reflect(:notification_will_retry, notification)
      end

      def retry_exponentially(notification)
        retry_after(notification, Time.now + 2 ** (notification.retries + 1))
      end

      def mark_delivered
        Rapns::Daemon.store.mark_delivered(@notification)
        reflect(:notification_delivered, @notification)
      end

      def mark_failed(code, description)
        Rapns::Daemon.store.mark_failed(@notification, code, description)
        reflect(:notification_failed, @notification)
      end
    end
  end
end
