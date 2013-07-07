module Rapns
  module Daemon
    class Batch
      include Reflectable

      attr_reader :num_processed, :notifications,
        :delivered, :failed, :retryable

      def initialize(notifications)
        @notifications = notifications
        @num_processed = 0
        @delivered = []
        @failed = {}
        @retryable = {}
        @mutex = Mutex.new
      end

      def num_notifications
        @notifications.size
      end

      def mark_retryable(notification, deliver_after)
        if Rapns.config.batch_storage_updates
          @retryable[deliver_after] ||= []
          @retryable[deliver_after] << notification
        else
          Rapns::Daemon.store.mark_retryable(notification, deliver_after)
        end
      end

      def mark_delivered(notification)
        if Rapns.config.batch_storage_updates
          @delivered << notification
        else
          Rapns::Daemon.store.mark_delivered(notification)
        end
      end

      def mark_failed(notification, code, description)
        if Rapns.config.batch_storage_updates
          key = [code, description]
          @failed[key] ||= []
          @failed[key] << notification
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

      def describe
        @notifications.map(&:id).join(', ')
      end

      private

      def complete
        [:complete_delivered, :complete_failed, :complete_retried].each do |method|
          begin
            send(method)
          rescue StandardError => e
            Rapns.logger.error(e)
            reflect(:error, e)
          end
        end

        @notifications.clear
        @complete = true
      end

      def complete_delivered
        Rapns::Daemon.store.mark_batch_delivered(@delivered)
        @delivered.clear
      end

      def complete_failed
        @failed.each do |(code, description), notifications|
          Rapns::Daemon.store.mark_batch_failed(notifications, code, description)
        end
        @failed.clear
      end

      def complete_retried
        @retryable.each do |deliver_after, notifications|
          Rapns::Daemon.store.mark_batch_retryable(notifications, deliver_after)
        end
        @retryable.clear
      end
    end
  end
end
