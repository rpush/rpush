module Rapns
  module Daemon
    class DeliveryQueue
      def initialize
        @queue = Queue.new
        @waiting_threads = []
        @mutex = Mutex.new
      end

      def push(obj)
        @queue.push(obj)
      end

      def pop
        @queue.pop
      end

      def signal_waiters_if_empty
        @mutex.synchronize do
          begin
            if @queue.size == 0
              t = @waiting_threads.shift
              t.wakeup if t
            end
          rescue ThreadError
            retry
          end
        end
      end

      def wait_until_empty
        Thread.exclusive do
          if @queue.size > 0
            @waiting_threads << Thread.current
            Thread.stop
          end
        end
      end
    end
  end
end