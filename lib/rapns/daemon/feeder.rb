class PGError < StandardError; end if !defined?(PGError)
module Mysql; class Error < StandardError; end; end if !defined?(Mysql)
module Mysql2; class Error < StandardError; end; end if !defined?(Mysql2)

ADAPTER_ERRORS = [PGError, Mysql::Error, Mysql2::Error]

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

          Rapns::Daemon.delivery_queue.wait_for_available_handler
        rescue ActiveRecord::StatementInvalid, *ADAPTER_ERRORS => e
          Rapns::Daemon.logger.error(e)
          reconnect
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        end

        sleep Rapns::Daemon.configuration.poll
      end

      def self.stop
        @stop = true
      end

      def self.reconnect
        Rapns::Daemon.logger.warn('Lost connection to database, reconnecting...')
        attempts = 0
        loop do
          begin
            Rapns::Daemon.logger.warn("Attempt #{attempts += 1}")
            ActiveRecord::Base.clear_all_connections!
            ActiveRecord::Base.establish_connection
            Rapns::Notification.count
            break
          rescue *ADAPTER_ERRORS => e
            Rapns::Daemon.logger.error(e, :airbrake_notify => false)
            sleep 2 # Avoid thrashing.
          end
        end
        Rapns::Daemon.logger.warn('Database reconnected')
      end
    end
  end
end