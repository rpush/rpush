module Rapns
  module Daemon
    class DeliveryHandlerCollection
      attr_reader :handlers

      def initialize
        @handlers = []
      end

      def push(handler)
        @handlers << handler
      end

      def pop
        handler = @handlers.pop
        handler.stop
        handler.wakeup
        @handlers.map(&:wakeup)
        handler.wait
      end

      def size
        @handlers.size
      end

      def stop
        @handlers.map(&:stop)
        @handlers.map(&:wakeup)
        @handlers.map(&:wait)
      end
    end
  end
end
