module Rapns
  module Daemon
    class Feeder
      extend InterruptibleSleep
      extend DatabaseReconnectable

      def self.name
        'Feeder'
      end

      def self.start(poll)
        if postgresql?
          register_listener

          loop do
            break if @stop
            enqueue_notifications
            wait_for_notifications
          end
        else
          loop do
            break if @stop
            enqueue_notifications
            interruptible_sleep poll
          end
        end
      end

      def self.stop
        @stop = true
        interrupt_sleep
      end

      protected

      def self.postgresql?
        Rapns::Notification.connection.adapter_name == 'PostgreSQL'
      end

      def self.reconnected
        register_listener if postgresql?
      end

      def self.register_listener
        Rapns::Notification.connection.execute("LISTEN #{Rapns::Notification::NOTIFY_CHANNEL}")
      end

      def self.wait_for_notifications
        Rapns::Notification.connection.raw_connection.wait_for_notify
      end

      def self.enqueue_notifications
        begin
          with_database_reconnect_and_retry do
            ready_apps = Rapns::Daemon::AppRunner.ready
            batch_size = Rapns::Daemon.configuration.feeder_batch_size
            Rapns::Notification.ready_for_delivery.find_each(:batch_size => batch_size) do |notification|
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