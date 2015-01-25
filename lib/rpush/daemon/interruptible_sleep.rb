require 'monitor'

module Rpush
  module Daemon
    class InterruptibleSleep
      def initialize(duration)
        @duration = duration
        @stop = false

        @wakeup_obj = Object.new
        @wakeup_obj.extend(MonitorMixin)
        @wakeup_condition = @wakeup_obj.new_cond

        @sleep_obj = Object.new
        @sleep_obj.extend(MonitorMixin)
        @sleep_condition = @sleep_obj.new_cond
      end

      def sleep
        return if @stop
        goto_sleep
        wait_for_wakeup
      end

      def start
        @stop = false

        @thread = Thread.new do
          loop do
            wait_for_sleeper
            break if @stop
            Kernel.sleep(@duration)
            wakeup
          end
        end
      end

      def stop
        @stop = true
        wakeup
        @thread.kill if @thread
      end

      def wakeup
        @wakeup_obj.synchronize { @wakeup_condition.signal }
      end

      private

      def goto_sleep
        @sleep_obj.synchronize { @sleep_condition.signal }
      end

      def wait_for_wakeup
        @wakeup_obj.synchronize { @wakeup_condition.wait(@duration * 2) }
      end

      def wait_for_sleeper
        @sleep_obj.synchronize { @sleep_condition.wait }
      end
    end
  end
end
