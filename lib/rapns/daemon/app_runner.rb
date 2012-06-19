module Rapns
	module Daemon
    class AppRunner
      HOSTS = {
        :production => {
          :push => ['gateway.push.apple.com', 2195],
          :feedback => ['feedback.push.apple.com', 2196]
        },
        :development => {
          :push => ['gateway.sandbox.push.apple.com', 2195],
          :feedback => ['feedback.sandbox.push.apple.com', 2196]
        }
      }

      class << self
        attr_reader :all
      end

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
            push_host, push_port = HOSTS[app.environment.to_sym][:push]
            feedback_host, feedback_port = HOSTS[app.environment.to_sym][:feedback]
            feedback_poll = Rapns::Daemon.config.feedback_poll
            runner = AppRunner.new(app, push_host, push_port, feedback_host, feedback_port, feedback_poll)
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

      def initialize(app, push_host, push_port, feedback_host, feedback_port, feedback_poll)
        @app = app
        @push_host = push_host
        @push_port = push_port
        @feedback_host = feedback_host
        @feedback_port = feedback_port
        @feedback_poll = feedback_poll

        @queue = DeliveryQueue.new
        @feedback_receiver = nil
        @handlers = []
      end

      def start
        @feedback_receiver = FeedbackReceiver.new(@app.key, @feedback_host, @feedback_port, @feedback_poll, @app.certificate, @app.password)
        @feedback_receiver.start

        @app.connections.times { @handlers << start_handler }
      end

      def deliver(notification)
        @queue.push(notification)
      end

      def stop
        @handlers.map(&:stop)
        @feedback_receiver.stop if @feedback_receiver
      end

      def sync(app)
        @app = app
        diff = @handlers.size - app.connections
        if diff > 0
          diff.times { @handlers.pop.stop }
        else
          diff.abs.times { @handlers << start_handler }
        end
      end

      def ready?
        @queue.notifications_processed?
      end

      def debug
        Rapns::Daemon.logger.info("\nAppRunner State:\n#{@app.key}:\n  handlers: #{@handlers.size}\n  backlog: #{@queue.size}\n  ready: #{ready?}")
      end

      protected

      def start_handler
        handler = DeliveryHandler.new(@queue, @app.key, @push_host, @push_port, @app.certificate, @app.password)
        handler.start
        handler
      end
    end
	end
end