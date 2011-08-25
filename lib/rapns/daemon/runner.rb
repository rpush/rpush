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

            msg = Rapns.logger.info("notification #{notification.id} delivered to #{notification.device_token}")
            puts msg if options[:foreground]
          end
        rescue Exception => e
          msg = Rapns.logger.error("#{e.class.name}, #{e.message}")
          puts msg if options[:foreground]
        end

        sleep options[:poll]
      end
    end
  end
end