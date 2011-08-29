module Rapns
  module Daemon
    class Runner
      def self.start(options)
        loop do
          break if @stop
          deliver_notifications(options)
        end
      end

      def self.deliver_notifications(options)
        begin
          Rapns::Notification.ready_for_delivery.each do |notification|
            Rapns::Daemon.connection_pool.write(notification.to_binary)

            notification.delivered = true
            notification.delivered_at = Time.now
            notification.save(:validate => false)

            Rapns::Daemon.logger.info("Notification #{notification.id} delivered to #{notification.device_token}")
          end
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        end

        sleep options[:poll]
      end

      def self.stop
        @stop = true
      end
    end
  end
end