module Rapns
  module Daemon
  	class DeliveryQueue18
      def push(obj)
        Thread.critical = true
        @queue.push obj
        @num_notifications += 1
        begin
          t = @waiting.shift
          t.wakeup if t
        rescue ThreadError
          retry
        ensure
          Thread.critical = false
        end
        begin
          t.run if t
        rescue ThreadError
        end
      end

      def pop
        while (Thread.critical = true; @queue.empty?)
          @waiting.push Thread.current
          Thread.stop
        end
        @queue.shift
      ensure
        Thread.critical = false
      end

      protected

      def synchronize
        Thread.critical = true
        begin
          yield
        ensure
          Thread.critical = false
        end
      end
  	end
  end
end