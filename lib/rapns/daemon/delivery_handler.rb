module Rapns
  module Daemon
    class DeliveryHandler
      include Reflectable

      WAKEUP = :wakeup

      attr_accessor :queue

      def start
        @thread = Thread.new do
          loop do
            handle_next_notification
            break if @stop
          end
        end
      end

      def stop
        @stop = true
      end

      def wakeup
        queue.push(WAKEUP) if @thread
      end

      def wait
        @thread.join if @thread
        stopped
      end

      protected

      def stopped
      end

      def handle_next_notification
        notification, batch = queue.pop
        return if notification == WAKEUP

        begin
          deliver(notification, batch)
        rescue StandardError => e
          Rapns.logger.error(e)
          reflect(:error, e)
        ensure
          batch.notification_processed
        end
      end
    end
  end
end
