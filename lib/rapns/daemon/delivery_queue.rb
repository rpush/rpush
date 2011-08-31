module Rapns
  module Daemon
    class DeliveryQueue
      def initialize
        @queue = Queue.new
        @waiting_threads = []
        @mutex = Mutex.new
        @counter = 0
      end

      def push(obj)
        @mutex.synchronize { @counter += 1 }
        @queue.push(obj)
      end

      def pop
        @queue.pop
      end

      def signal
        @mutex.synchronize do
          begin
            @counter -= 1
            if @counter <= 0
              t = @waiting_threads.shift
              t.wakeup if t
            end
          rescue ThreadError
            retry
          end
        end
      end

      def wait
        Thread.exclusive do
          if @counter > 0
            @waiting_threads << Thread.current
            Thread.stop
          end
        end
      end
    end
  end
end