module Rapns
  module Daemon
    class Feeder
      def self.start
        loop do
          break if @stop
          enqueue_notifications
        end
      end

      def self.enqueue_notifications
        begin
          Rapns::Notification.ready_for_delivery.each do |notification|
            Rapns::Daemon.delivery_queue.push(notification)
          end

          Rapns::Daemon.delivery_queue.wait
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        end

        sleep Rapns::Daemon.configuration.poll
      end

      def self.stop
        @stop = true
      end
    end
  end
end