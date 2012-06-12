module Rapns
  module Daemon
    class Feeder
      extend InterruptibleSleep
      extend DatabaseReconnectable

      def self.name
        'Feeder'
      end

      def self.start(poll)
        loop do
          break if @stop
          enqueue_notifications
          interruptible_sleep poll
        end
      end

      def self.stop
        @stop = true
        interrupt_sleep
      end

      protected

      def self.enqueue_notifications
        begin
          with_database_reconnect_and_retry do
            Rapns::Notification.ready_for_delivery.each do |notification|
              if queue = Rapns::Daemon.queues[notification.app]
                queue.push(notification) if queue.notifications_processed?
              else
                Rapns::Daemon.logger.error("rapns not configured for app '#{notification.app}'.")
              end
            end
          end
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        end
      end
    end
  end
end