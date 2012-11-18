module Rapns
  module Daemon
    class AppRunner
      class << self
        attr_reader :runners # TODO: Needed?
      end

      @runners = {}

      def self.enqueue(notification)
        if app = @runners[notification.app_id]
          app.enqueue(notification)
        else
          Rapns::Daemon.logger.error("No such app '#{notification.app_id}' for notification #{notification.id}.")
        end
      end

      def self.sync
        apps = Rapns::App.all
        apps.each do |app|
          if @runners[app.id]
            @runners[app.id].sync(app)
          else
            runner = new_runner_for_app(app)
            begin
              runner.start
              @runners[app.id] = runner
            rescue StandardError => e
              Rapns::Daemon.logger.error("[App:#{app.name}] failed to start. No notifications will be sent.")
              Rapns::Daemon.logger.error(e)
            end
          end
        end

        removed = @runners.keys - apps.map(&:id)
        removed.each { |app_id| @runners.delete(app_id).stop }
      end

      def self.new_runner_for_app(app)
        if app.is_a?(Rapns::Apns::App)
          Rapns::Daemon::Apns::AppRunner.new(app)
        elsif app.is_a?(Rapns::Gcm::App)
          Rapns::Daemon::Gcm::AppRunner.new(app)
        else
          raise NotImplementedError
        end
      end

      def self.stop
        @runners.values.map(&:stop)
      end

      def self.debug
        @runners.values.map(&:debug)
      end

      def self.idle
        runners.values.find_all { |runner| runner.idle? }
      end

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def new_delivery_handler
        raise NotImplementedError
      end

      def started
      end

      def stopped
      end

      def start
        app.connections.times { handlers << start_handler }
        started
      end

      def stop
        handlers.map(&:stop)
        stopped
      end

      def enqueue(notification)
        queue.push(notification) if idle?
      end

      def sync(app)
        @app = app
        diff = handlers.size - app.connections
        if diff > 0
          diff.times { handlers.pop.stop }
        else
          diff.abs.times { handlers << start_handler }
        end
      end

      def idle?
        pool.mailbox_size == 0
      end

      def debug
        Rapns::Daemon.logger.info("\nApp State:\n#{@app.name}:\n  handlers: #{handlers.size}\n  backlog: #{queue.size}\n  idle: #{idle?}")
      end

      def idle?
        queue.notifications_processed?
      end

      protected

      def start_handler
        handler = new_delivery_handler
        handler.queue = queue
        handler.start
        handler
      end

      def queue
        @queue ||= Rapns::Daemon::DeliveryQueue.new
      end

      def handlers
        @handler ||= []
      end
    end
  end
end
