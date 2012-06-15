module Rapns
  module Daemon
    class DeliveryQueue
      def initialize
        @mutex = Mutex.new
        @num_notifications = 0
        @queue = Queue.new
      end

      def push(notification)
        @mutex.synchronize { @num_notifications += 1 }
        @queue.push(notification)
      end

      def pop
        @queue.pop
      end

      def notification_processed
        @mutex.synchronize { @num_notifications -= 1 }
      end

      def notifications_processed?
        @mutex.synchronize { @num_notifications == 0 }
      end

      def size
        @queue.size
      end
    end
  end
end