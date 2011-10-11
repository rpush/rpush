module Rapns
  module Daemon
    class DeliveryQueue
      def initialize(num_handlers)
        @num_handlers = num_handlers
        @queue = Queue.new
        @feeder_threads = []
        @mutex = Mutex.new
      end

      def push(obj)
        @queue.push(obj)
      end

      def pop
        @queue.pop
      end

      def handler_available
        @mutex.synchronize do
          signal_feeder if handler_available?
        end
      end

      def handler_available?
        @queue.size < @num_handlers
      end

      def signal_feeder
        begin
          t = @feeder_threads.shift
          t.wakeup if t
        rescue ThreadError
          retry
        end
      end

      def wait_for_available_handler
        Thread.exclusive do
          if @queue.size >= @num_handlers
            @feeder_threads << Thread.current
            Thread.stop
          end
        end
      end
    end
  end
end