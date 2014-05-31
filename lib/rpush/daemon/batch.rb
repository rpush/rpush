module Rpush
  module Daemon
    class Batch
      include Reflectable

      attr_reader :notifications, :num_processed, :delivered, :failed, :retryable

      def initialize(notifications)
        @notifications = notifications
        @num_processed = 0
        @delivered = []
        @failed = {}
        @retryable = {}
        @mutex = Mutex.new
      end

      def complete?
        @complete == true
      end

      def mark_retryable(notification, deliver_after)
        if Rpush.config.batch_storage_updates
          @mutex.synchronize do
            @retryable[deliver_after] ||= []
            @retryable[deliver_after] << notification
          end
          Rpush::Daemon.store.mark_retryable(notification, deliver_after, persist: false)
        else
          Rpush::Daemon.store.mark_retryable(notification, deliver_after)
          reflect(:notification_will_retry, notification)
        end
      end

      def mark_delivered(notification)
        if Rpush.config.batch_storage_updates
          @mutex.synchronize do
            @delivered << notification
          end
          Rpush::Daemon.store.mark_delivered(notification, Time.now, persist: false)
        else
          Rpush::Daemon.store.mark_delivered(notification, Time.now)
          reflect(:notification_delivered, notification)
        end
      end

      def mark_failed(notification, code, description)
        if Rpush.config.batch_storage_updates
          key = [code, description]
          @mutex.synchronize do
            @failed[key] ||= []
            @failed[key] << notification
          end
          Rpush::Daemon.store.mark_failed(notification, code, description, Time.now, persist: false)
        else
          Rpush::Daemon.store.mark_failed(notification, code, description, Time.now)
          reflect(:notification_failed, notification)
        end
      end

      def notification_dispatched
        @mutex.synchronize do
          @num_processed += 1
          complete if @num_processed >= @notifications.size
        end
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
            Rpush.logger.error(e)
            reflect(:error, e)
          end
        end

        @notifications.clear
        @complete = true
      end

      def complete_delivered
        Rpush::Daemon.store.mark_batch_delivered(@delivered)
        @delivered.each do |notification|
          reflect(:notification_delivered, notification)
        end
        @delivered.clear
      end

      def complete_failed
        @failed.each do |(code, description), notifications|
          Rpush::Daemon.store.mark_batch_failed(notifications, code, description)
          notifications.each do |notification|
            reflect(:notification_failed, notification)
          end
        end
        @failed.clear
      end

      def complete_retried
        @retryable.each do |deliver_after, notifications|
          Rpush::Daemon.store.mark_batch_retryable(notifications, deliver_after)
          notifications.each do |notification|
            reflect(:notification_will_retry, notification)
          end
        end
        @retryable.clear
      end
    end
  end
end
