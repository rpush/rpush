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
            delivered_at = Time.now

            notification.delivered = true
            notification.delivered_at = delivered_at
            notification.save(:validate => false)

            msg = "[#{delivered_at.to_s(:db)}] notification #{notification.id} delivered to #{notification.device_token}"
            Rapns.logger.info(msg)
            puts msg if options[:foreground]
          end
        rescue Exception => e
          msg = "[ERROR] [#{Time.now.to_s(:db)}] #{e.class.name}, #{e.message}"
          Rapns.logger.error(msg)
          puts msg if options[:foreground]
        end

        sleep options[:poll]
      end
    end
  end
end