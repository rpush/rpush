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

      def self.sync(environment)
        apps = Rapns::App.where(:environment => environment)

        apps.each do |app|
          if @all[app.key]
            @all[app.key].sync(app)
          else
            push = Rapns::Daemon.configuration.push
            feedback = Rapns::Daemon.configuration.feedback
            runner = AppRunner.new(app, push.host, push.port, feedback.host, feedback.port, feedback.poll)
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

        @app.connections.times do
          handler = DeliveryHandler.new(@queue, @app.key, @push_host, @push_port, @app.certificate, @app.password)
          handler.start
          @handlers << handler
        end
      end

      def deliver(notification)
        return unless @queue.notifications_processed?
        @queue.push(notification)
      end

      def stop
        @handlers.map(&:stop)
        @feedback_receiver.stop if @feedback_receiver
      end
    end
	end
end