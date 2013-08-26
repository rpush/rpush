module Rapns
  module Daemon
    class AppRunner
      extend Reflectable
      include Reflectable

      class << self
        attr_reader :runners
      end

      @runners = {}

      def self.enqueue(notifications)
        notifications.group_by(&:app_id).each do |app_id, group|
          batch = Batch.new(group)
          if app = runners[app_id]
            app.enqueue(batch)
          else
            Rapns.logger.error("No such app '#{app_id}' for notifications #{batch.describe}.")
          end
        end
      end

      def self.sync
        apps = Rapns::App.all
        apps.each { |app| sync_app(app) }
        removed = runners.keys - apps.map(&:id)
        removed.each { |app_id| runners.delete(app_id).stop }
      end

      def self.sync_app(app)
        if runners[app.id]
          runners[app.id].sync(app)
        else
          runner = new_runner(app)
          begin
            runner.start
            runners[app.id] = runner
          rescue StandardError => e
            Rapns.logger.error("[#{app.name}] Exception raised during startup. Notifications will not be delivered for this app.")
            Rapns.logger.error(e)
            reflect(:error, e)
          end
        end
      end

      def self.new_runner(app)
        type = app.class.parent.name.demodulize
        "Rapns::Daemon::#{type}::AppRunner".constantize.new(app)
      end

      def self.stop
        runners.values.map(&:stop)
        runners.clear
      end

      def self.debug
        runners.values.map(&:debug)
      end

      def self.idle
        runners.values.select(&:idle?)
      end

      def self.wait
        sleep 0.1 while !runners.values.all?(&:idle?)
      end

      attr_reader :app
      attr_accessor :batch

      def initialize(app)
        @app = app
      end

      def before_start; end
      def after_start; end
      def before_stop; end
      def after_stop; end

      def start
        before_start
        app.connections.times { handlers.push(start_handler) }
        after_start
        Rapns.logger.info("[#{app.name}] Started, #{handlers_str}.")
      end

      def stop
        before_stop
        handlers.stop
        after_stop
      end

      def enqueue(batch)
        self.batch = batch
        batch.notifications.each do |notification|
          queue.push([notification, batch])
          reflect(:notification_enqueued, notification)
        end
      end

      def sync(app)
        @app = app
        diff = handlers.size - app.connections
        return if diff == 0
        if diff > 0
          decrement_handlers(diff)
          Rapns.logger.info("[#{app.name}] Stopped #{handlers_str(diff)}. #{handlers_str} running.")
        else
          increment_handlers(diff.abs)
          Rapns.logger.info("[#{app.name}] Started #{handlers_str(diff)}. #{handlers_str} running.")
        end
      end

      def decrement_handlers(num)
        num.times { handlers.pop }
      end

      def increment_handlers(num)
        num.times { handlers.push(start_handler) }
      end

      def debug
        Rapns.logger.info <<-EOS

#{@app.name}:
  handlers: #{num_handlers}
  queued: #{queue_size}
  batch size: #{batch_size}
  batch processed: #{batch_processed}
  idle: #{idle?}
        EOS
      end

      def idle?
        batch ? batch.complete? : true
      end

      def queue_size
        queue.size
      end

      def batch_size
        batch ? batch.num_notifications : 0
      end

      def batch_processed
        batch ? batch.num_processed : 0
      end

      def num_handlers
        handlers.size
      end

      protected

      def start_handler
        handler = new_delivery_handler
        handler.queue = queue
        handler.start
        handler
      end

      def queue
        @queue ||= Queue.new
      end

      def handlers
        @handlers ||= Rapns::Daemon::DeliveryHandlerCollection.new
      end

      def handlers_str(count = app.connections)
        count = count.abs
        str = count == 1 ? 'handler' : 'handlers'
        "#{count} #{str}"
      end
    end
  end
end
