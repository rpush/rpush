module Rpush
  module Daemon
    class AppRunner
      extend Reflectable
      include Reflectable
      include Loggable

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
            Rpush.logger.error("No such app '#{app_id}' for notifications #{batch.describe}.")
          end
        end
      end

      def self.sync
        apps = Rpush::Daemon.store.all_apps
        apps.each { |app| sync_app(app) }
        removed = runners.keys - apps.map(&:id)
        removed.each { |app_id| runners.delete(app_id).stop }
      end

      def self.sync_app(app)
        if runners[app.id]
          runners[app.id].sync(app)
        else
          runner = new(app)
          begin
            runner.start
            runners[app.id] = runner
          rescue StandardError => e
            Rpush.logger.error("[#{app.name}] Exception raised during startup. Notifications will not be delivered for this app.")
            Rpush.logger.error(e)
            reflect(:error, e)
          end
        end
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
        @loops = []
      end

      def start
        app.connections.times { dispatchers.push(new_dispatcher_loop) }
        start_loops
        log_info("Started, #{dispatchers_str}.")
      end

      def stop
        dispatchers.stop
        stop_loops
        self.batch = nil
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
        diff = dispatchers.size - app.connections
        return if diff == 0
        if diff > 0
          decrement_dispatchers(diff)
          log_info("Stopped #{dispatchers_str(diff)}. #{dispatchers_str} running.")
        else
          increment_dispatchers(diff.abs)
          log_info("Started #{dispatchers_str(diff)}. #{dispatchers_str} running.")
        end
      end

      def decrement_dispatchers(num)
        num.times { dispatchers.pop }
      end

      def increment_dispatchers(num)
        num.times { dispatchers.push(new_dispatcher_loop) }
      end

      def debug
        Rpush.logger.info <<-EOS

#{@app.name}:
  dispatchers: #{num_dispatchers}
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

      def num_dispatchers
        dispatchers.size
      end

      protected

      def start_loops
        service_module.loops.each do |loop_class|
          instance = loop_class.new(@app)
          instance.start
          @loops << instance
        end
      end

      def stop_loops
        @loops.map(&:stop)
        @loops = []
      end

      def new_dispatcher_loop
        dispatcher = service_module.new_dispatcher(@app)
        dispatcher_loop = Rpush::Daemon::DispatcherLoop.new(queue, dispatcher)
        dispatcher_loop.start
        dispatcher_loop
      end

      def service_module
        return @service_module if defined? @service_module
        @service_module = "Rpush::Daemon::#{@app.service_name.camelize}".constantize
      end

      def queue
        @queue ||= Queue.new
      end

      def dispatchers
        @dispatchers ||= Rpush::Daemon::DispatcherLoopCollection.new
      end

      def dispatchers_str(count = app.connections)
        count = count.abs
        str = count == 1 ? 'dispatcher' : 'dispatchers'
        "#{count} #{str}"
      end
    end
  end
end
