module Rapns
	module Daemon
    class AppRunner
      class << self
        attr_reader :all
      end

      @all = {}

      def self.deliver(notification)
        if app = @all[notification.app]
          app.deliver(notification)
        else
          Rapns::Daemon.logger.error("No such app '#{notification.app}' for notification #{notification.id}.")
        end
      end

      def self.sync
        apps = Rapns::App.all
        apps.each do |app|
          if @all[app.key]
            @all[app.key].sync(app)
          else
            runner = new_runner_for_app(app)
            runner.start
            @all[app.key] = runner
          end
        end

        removed = @all.keys - apps.map(&:key)
        removed.each { |key| @all.delete(key).stop }
      end

      def self.runner_class_for_app(app)
        # Violates tell don't ask, but we can't reference Daemon scope in the client code.
        case app.class
        when Rapns::Apns::App
          Rapns::Daemon::Apns::AppRunner.new(app)
        else
          raise NotImplementedError
        end
      end

      def self.stop
        @all.values.map(&:stop)
      end

      def self.debug
        @all.values.map(&:debug)
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

      def deliver(notification)
        queue.push(notification) if ready?
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

      def debug
        Rapns::Daemon.logger.info("\nApp State:\n#{key}:\n  handlers: #{handlers.size}\n  backlog: #{queue.size}\n  ready: #{ready?}")
      end

      def ready?
        queue.notifications_processed?
      end

      protected

      def start_handler
        handler = new_delivery_handler
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