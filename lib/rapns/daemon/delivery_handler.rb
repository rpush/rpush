module Rapns
  module Daemon
    class DeliveryHandler
      include DatabaseReconnectable

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
        queue.wakeup(@thread) if @thread
      end

      protected

      def close
      end

      def handle_next_notification
        begin
          notification = queue.pop
        rescue DeliveryQueue::WakeupError
          close
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

      def handle_delivery_error(notification, code, description)
        with_database_reconnect_and_retry do
          notification.delivered = false
          notification.delivered_at = nil
          notification.failed = true
          notification.failed_at = Time.now
          notification.error_code = code
          notification.error_description = description
          notification.save!(:validate => false)
        end
      end
    end
  end
end