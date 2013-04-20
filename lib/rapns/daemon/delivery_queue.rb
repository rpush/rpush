module Rapns
  module Daemon
    if RUBY_VERSION < '1.9'
      require 'rapns/daemon/delivery_queue_18'
      ancestor_class = DeliveryQueue18
    else
      require 'rapns/daemon/delivery_queue_19'
      ancestor_class = DeliveryQueue19
    end

    class DeliveryQueue < ancestor_class
      class WakeupError < StandardError; end

      def initialize
        @num_notifications = 0
        @queue = []
        @waiting = []

        super
      end

      def wakeup(thread)
        synchronize do
          t = @waiting.delete(thread)
          t.raise WakeupError if t
        end
      end

      def size
        synchronize { @queue.size }
      end

      def notification_processed
        synchronize { @num_notifications -= 1 }
      end

      def notifications_processed?
        synchronize { @num_notifications <= 0 }
      end
    end
  end
end
