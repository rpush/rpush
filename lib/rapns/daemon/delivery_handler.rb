module Rapns
  module Daemon
    class DeliveryHandler
      attr_accessor :queue

      def deliver(notification)
        raise NotImplementedError
      end

      def start
        @thread = Thread.new do
          loop do
            break if @stop
            handle_next_notification
          end
        end
      end

      def stop
        @stop = true
        if @thread
          queue.wakeup(@thread)
          @thread.join
        end
        stopped
      end

      def stopped
      end

      def handle_next_notification
        begin
          notification = queue.pop
        rescue DeliveryQueue::WakeupError
          return
        end

        begin
          deliver(notification)
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        ensure
          queue.notification_processed
        end
      end
    end
  end
end