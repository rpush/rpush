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
            ready_apps = Rapns::Daemon::AppRunner.ready
            Rapns::Notification.ready_for_delivery.each do |notification|
              Rapns::Daemon::AppRunner.deliver(notification) if ready_apps.include?(notification.app)
            end
          end
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        end
      end
    end
  end
end