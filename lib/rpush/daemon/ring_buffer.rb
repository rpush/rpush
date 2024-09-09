module Rpush
  module Daemon
    class RingBuffer < Array
      def initialize(max_size)
        @max_size = max_size
      end

      def <<(obj)
        shift if size >= @max_size
        super
      end

      alias push <<
    end
  end
end
