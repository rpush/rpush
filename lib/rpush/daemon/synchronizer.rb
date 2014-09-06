module Rpush
  module Daemon
    class Synchronizer
      extend Loggable
      extend StringHelpers

      def self.sync
        apps = Rpush::Daemon.store.all_apps
        apps.each { |app| sync_app(app) }
        removed = AppRunner.app_ids - apps.map(&:id)
        removed.each { |app_id| AppRunner.stop_app(app_id) }

        ProcTitle.update
      end

      def self.sync_app(app)
        unless AppRunner.app_running?(app)
          AppRunner.start_app(app)
          return
        end

        sync_dispatcher_count(app)
      end

      def self.sync_dispatcher_count(app)
        num_dispatchers = AppRunner.num_dispatchers_for_app(app)
        diff = num_dispatchers - app.connections
        return if diff == 0

        if diff > 0
          AppRunner.decrement_dispatchers(app, diff)
          start_stop_str = "Stopped"
        else
          AppRunner.increment_dispatchers(app, diff.abs)
          start_stop_str = "Started"
        end

        num_dispatchers = AppRunner.num_dispatchers_for_app(app)
        log_info("[#{app.name}] #{start_stop_str} #{pluralize(diff.abs, 'dispatcher')}. #{num_dispatchers} running.")
      end
    end
  end
end
