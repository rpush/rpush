class PGError < StandardError; end if !defined?(PGError)
module Mysql; class Error < StandardError; end; end if !defined?(Mysql)
module Mysql2; class Error < StandardError; end; end if !defined?(Mysql2)

ADAPTER_ERRORS = [PGError, Mysql::Error, Mysql2::Error]

module Rapns
  module Daemon
    class Feeder
      def self.start(foreground)
        connect unless foreground

        loop do
          break if @stop
          enqueue_notifications
        end
      end

      def self.stop
        @stop = true
      end

      protected

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

      def self.reconnect
        Rapns::Daemon.logger.warn('Lost connection to database, reconnecting...')
        attempts = 0
        loop do
          begin
            Rapns::Daemon.logger.warn("Attempt #{attempts += 1}")
            connect
            check_is_connected
            break
          rescue *ADAPTER_ERRORS => e
            Rapns::Daemon.logger.error(e, :airbrake_notify => false)
            sleep_to_avoid_thrashing
          end
        end
        Rapns::Daemon.logger.warn('Database reconnected')
      end

      def self.connect
        ActiveRecord::Base.clear_all_connections!
        ActiveRecord::Base.establish_connection
      end

      def self.check_is_connected
        # Simply asking the adapter for the connection state is not sufficient.
        Rapns::Notification.count
      end

      def self.sleep_to_avoid_thrashing
        sleep 2
      end
    end
  end
end