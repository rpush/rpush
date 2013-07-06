module Rapns
  module Daemon
    class Batch
      def initialize(num_notifications)
        @num_notifications = num_notifications
        @delivered = []
        @failed = []
        @retried = []
        @num_processed = 0
      end

      def retry_after(notification, deliver_after)
        if Rapns.config.batch_storage_writes
          # TODO: group by deliver_after
          @retried << notification
        else
          Rapns::Daemon.store.retry_after(notification, deliver_after)
        end
      end

      def mark_delivered(notification)
        if Rapns.config.batch_storage_writes
          @delivered << notification
        else
          Rapns::Daemon.store.mark_delivered(notification)
        end
      end

      def mark_failed(notification, code, description)
        if Rapns.config.batch_storage_writes
          # TODO: group by code, description
          @failed << notification
        else
          Rapns::Daemon.store.mark_failed(notification, code, description)
        end
      end

      def notification_processed
        @mutex.synchronize do
          @num_processed += 1
          complete if @num_processed >= @notifications.size
        end
      end

      def complete?
        @complete == true
      end

      private

      def complete
        Rapns::Daemon.store.mark_batch_delivered(@delivered_notifications)
        @delivered_notifications.clear
        @notifications.clear
        @complete = true
      end
    end
  end
end
