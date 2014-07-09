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
          sync_app_with_id(app_id) unless runners[app_id]
          runners[app_id].enqueue(group) if runners[app_id]
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
            runners[app.id] = runner
            runner.start
          rescue StandardError => e
            Rpush.logger.error("[#{app.name}] Exception raised during startup. Notifications will not be delivered for this app.")
            Rpush.logger.error(e)
            reflect(:error, e)
          end
        end
      end

      def self.sync_app_with_id(app_id)
        sync_app(Rpush::Daemon.store.app(app_id))
      end

      def self.stop
        runners.values.map(&:stop)
        runners.clear
      end

      def self.cumulative_queue_size
        size = 0
        runners.values.each { |runner| size += runner.queue_size }
        size
      end

      def self.debug
        runners.values.map(&:debug)
      end

      attr_reader :app

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
        wait_until_idle
        dispatchers.stop
        @dispatchers = nil
        stop_loops
      end

      def wait_until_idle
        sleep 0.5 while queue.size > 0
      end

      def enqueue(notifications)
        if service.batch_deliveries?
          batch_size = (notifications.size / num_dispatchers).ceil
          notifications.in_groups_of(batch_size, false).each do |batch_notifications|
            batch = Batch.new(batch_notifications)
            queue.push(QueuePayload.new(batch: batch))
          end
        else
          batch = Batch.new(notifications)
          notifications.each do |notification|
            queue.push(QueuePayload.new(batch: batch, notification: notification))
            reflect(:notification_enqueued, notification)
          end
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
        EOS
      end

      def queue_size
        queue.size
      end

      def num_dispatchers
        dispatchers.size
      end

      private

      def start_loops
        @loops = service.loop_instances(@app)
        @loops.map(&:start)
      end

      def stop_loops
        @loops.map(&:stop)
        @loops = []
      end

      def new_dispatcher_loop
        dispatcher = service.new_dispatcher(@app)
        dispatcher_loop = Rpush::Daemon::DispatcherLoop.new(queue, dispatcher)
        dispatcher_loop.start
        dispatcher_loop
      end

      def service
        return @service if defined? @service
        @service = "Rpush::Daemon::#{@app.service_name.camelize}".constantize
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
