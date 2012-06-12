module Rapns
  module Daemon
    class DeliveryHandlerPool
      def initialize
        @handlers = []
      end

      def <<(handler)
        @handlers << handler
        handler.start
      end

      def drain
        @handlers.pop.stop while !@handlers.empty?
      end
    end
  end
end