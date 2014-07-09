require 'monitor'

module Rpush
  module Daemon
    class InterruptibleSleep
      def initialize(duration)
        @duration = duration
        @obj = Object.new
        @obj.extend(MonitorMixin)
        @condition = @obj.new_cond
        @stop = false
      end

      def sleep
        return if @stop
        @obj.synchronize { @condition.wait(100_000) }
      end

      def start
        @stop = false

        @thread = Thread.new do
          loop do
            break if @stop
            Kernel.sleep(@duration)
            signal
          end
        end
      end

      def stop
        @stop = true
        signal
        @thread.kill if @thread
      end

      def wakeup
        signal
      end

      private

      def signal
        @obj.synchronize { @condition.signal }
      end
    end
  end
end
