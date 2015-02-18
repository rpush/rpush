require 'monitor'

module Rpush
  module Daemon
    class InterruptibleSleep
      def sleep(duration)
        @thread = Thread.new { Kernel.sleep duration }
        Thread.pass
        @thread.join
      end

      def stop
        @thread.kill if @thread
      rescue StandardError # rubocop:disable Lint/HandleExceptions
      end
    end
  end
end
