module Rapns
  module Daemon
    class Runner
      def self.start(options)
        loop { deliver_notifications(options) }
      end

      def self.deliver_notifications(options)
        begin
          Rapns::Notification.undelivered.each do |notification|
            Rapns::Daemon::Connection.write(notification.to_binary)

            notification.delivered = true
            notification.delivered_at = Time.now
            notification.save(:validate => false)

            Rapns.logger.info("Notification #{notification.id} delivered to #{notification.device_token}")
          end
        rescue Exception => e
          Rapns.logger.error("#{e.class.name}, #{e.message}")
        end

        sleep options[:poll]
      end
    end
  end
end