module Rapns
  module Daemon
    class Runner
      def self.start(options)
        loop do
          break if Rapns::Daemon.shutdown?
          deliver_notifications(options)
        end
      end

      def self.deliver_notifications(options)
        begin
          Rapns::Notification.undelivered.each do |notification|
            Rapns::Daemon.connection.write(notification.to_binary)

            notification.delivered = true
            notification.delivered_at = Time.now
            notification.save(:validate => false)

            Rapns::Daemon.logger.info("Notification #{notification.id} delivered to #{notification.device_token}")
          end
        rescue Exception => e
          Rapns::Daemon.logger.error("#{e.class.name}, #{e.message}")
        end

        sleep options[:poll]
      end
    end
  end
end