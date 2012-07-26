module Rapns
	module Daemon
    class AppRunner
      class << self
        attr_reader :all
      end

      attr_accessor :app

      @all = {}

      def self.ready
        ready = []
        @all.each { |app, runner| ready << app if runner.ready? }
        ready
      end

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
            runner = app.new_runner
            runner.start
            @all[app.key] = runner
          end
        end

        removed = @all.keys - apps.map(&:key)
        removed.each { |key| @all.delete(key).stop }
      end

      def self.stop
        @all.values.map(&:stop)
      end

      def self.debug
        @all.values.map(&:debug)
      end

      def start
        app.connections.times { handlers << start_handler }
        started
      end

      def deliver(notification)
        queue.push(notification)
      end

      def stop
        handlers.map(&:stop)
        stopped
      end

      def sync(app)
        self.app = app
        diff = handlers.size - app.connections
        if diff > 0
          diff.times { handlers.pop.stop }
        else
          diff.abs.times { handlers << start_handler }
        end
      end

      def ready?
        queue.notifications_processed?
      end

      def debug
        Rapns::Daemon.logger.info("\nAppRunner State:\n#{app.key}:\n  handlers: #{handlers.size}\n  backlog: #{queue.size}\n  ready: #{ready?}")
      end

      protected

      def started
      end

      def stopped
      end

      def start_handler
        raise NotImplementedError
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