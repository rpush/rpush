module Rapns
  module Daemon
    class DeliveryQueue
      class WakeupError < StandardError; end

      def initialize
        @mutex = Mutex.new
        @num_notifications = 0
        @queue = []
        @waiting = []
      end

      def push(notification)
        @mutex.synchronize do
          @num_notifications += 1
          @queue.push(notification)

          begin
            t = @waiting.shift
            t.wakeup if t
          rescue ThreadError
            retry
          end
        end
      end

      def pop
        @mutex.synchronize do
          while true
            if @queue.empty?
              @waiting.push Thread.current
              @mutex.sleep
            else
              return @queue.shift
            end
          end
        end
      end

      def wakeup(thread)
        @mutex.synchronize do
          t = @waiting.delete(thread)
          t.raise WakeupError if t
        end
      end

      def size
        @mutex.synchronize { @queue.size }
      end

      def notification_processed
        @mutex.synchronize { @num_notifications -= 1 }
      end

      def notifications_processed?
        @mutex.synchronize { @num_notifications == 0 }
      end
    end
  end
end