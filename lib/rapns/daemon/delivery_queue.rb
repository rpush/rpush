module Rapns
  module Daemon
    class DeliveryQueue
      def initialize(num_handlers)
        @num_handlers = num_handlers
        @queue = Queue.new
        @feeder = nil
        @handler_mutex = Mutex.new
      end

      def push(obj)
        @queue.push(obj)
      end

      def pop
        @queue.pop
      end

      def handler_available
        @handler_mutex.synchronize do
          signal_feeder if handler_available?
        end
      end

      def handler_available?
        @queue.size < @num_handlers
      end

      def signal_feeder
        begin
          @feeder.wakeup if @feeder
        rescue ThreadError
          retry
        end
      end

      def wait_for_available_handler
        if !handler_available?
          @feeder = Thread.current
          @feeder.stop
        end
      end
    end
  end
end