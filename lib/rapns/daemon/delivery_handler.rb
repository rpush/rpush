module Rapns
  module Daemon
    class DeliveryHandler
      include Reflectable

      NOOP = :noop

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
        if @thread
          queue.push(NOOP)
          @thread.join
        end
        stopped
      end

      protected

      def stopped
      end

      def handle_next_notification
        notification, batch = queue.pop
        return if notification == NOOP

        begin
          deliver(notification, batch)
          reflect(:notification_delivered, notification)
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
