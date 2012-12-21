module Rapns
  module Daemon
    class Feeder
      extend InterruptibleSleep
      extend DatabaseReconnectable
      extend Reflectable

      def self.start
        @stop = false

        if Rapns.config.embedded
          Thread.new { feed_forever }
        elsif Rapns.config.push
          enqueue_notifications
        else
          feed_forever
        end
      end

      def self.stop
        @stop = true
        interrupt_sleep
      end

      protected

      def self.feed_forever
        loop do
          enqueue_notifications
          interruptible_sleep(Rapns.config.push_poll)
          break if stop?
        end
      end

      def self.stop?
        @stop
      end

      def self.enqueue_notifications
        begin
          with_database_reconnect_and_retry do
            batch_size = Rapns.config.batch_size
            idle = Rapns::Daemon::AppRunner.idle.map(&:app)
            relation = Rapns::Notification.ready_for_delivery.for_apps(idle)
            relation = relation.limit(batch_size) unless Rapns.config.push
            relation.each do |notification|
              Rapns::Daemon::AppRunner.enqueue(notification)
              reflect(:notification_enqueued, notification)
            end
          end
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
          reflect(:error, e)
        end
      end
    end
  end
end
