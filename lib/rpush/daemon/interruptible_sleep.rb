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
        @obj.synchronize do
          return if @stop
          @condition.wait(100_000)
        end
      end

      def start
        @thread = Thread.new do
          loop do
            break if @stop
            Kernel.sleep(@duration)
            signal
          end
        end
      end

      def stop
        @obj.synchronize { @stop = true }
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
