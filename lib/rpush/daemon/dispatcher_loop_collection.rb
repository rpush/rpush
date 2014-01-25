module Rpush
  module Daemon
    class DispatcherLoopCollection
      attr_reader :loops

      def initialize
        @loops = []
      end

      def push(dispatcher_loop)
        @loops << dispatcher_loop
      end

      def pop
        dispatcher_loop = @loops.pop
        dispatcher_loop.stop
        dispatcher_loop.wakeup
        @loops.map(&:wakeup)
        dispatcher_loop.wait
      end

      def size
        @loops.size
      end

      def stop
        @loops.map(&:stop)
        @loops.map(&:wakeup)
        @loops.map(&:wait)
      end
    end
  end
end
