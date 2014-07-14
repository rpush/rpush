module Rpush
  module Daemon
    class ProcTitle
      def self.update
        $0 = proc_title
      end

      def self.proc_title
        total_dispatchers = AppRunner.total_dispatchers
        dispatchers_str = total_dispatchers == 1 ? 'dispatcher' : 'dispatchers'
        total_queued = AppRunner.total_queued
        format("rpush | %s | %d queued | %d %s", Rpush.config.environment, total_queued, total_dispatchers, dispatchers_str)
      end
    end
  end
end
