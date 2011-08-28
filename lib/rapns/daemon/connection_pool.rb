module Rapns
  module Daemon
    class ConnectionPool
      def initialize(size = 3)
        @size = size
        @queue = Queue.new
        @pool = []
      end

      def populate
        @size.times { |i| @pool << Connection.new("Connection #{i}", @queue) }
        @pool.map(&:connect)
      end

      def write(msg)
        @queue.push(msg)
      end

      def drain
        @pool.map(&:close)
      end
    end
  end
end