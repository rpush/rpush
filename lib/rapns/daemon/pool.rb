module Rapns
  module Daemon
    class Pool
      def initialize(num_objects)
        @num_objects = num_objects
        @queue = Queue.new
      end

      def populate
        @num_objects.times do |i|
          object = new_object_for_pool(i)
          @queue.push(object)
          object_added_to_pool(object)
        end
      end

      def drain
        while !@queue.empty?
          object = @queue.pop
          object_removed_from_pool(object)
        end
      end

      protected

      def new_object_for_pool(i)
        raise NotImplementedError
      end

      def object_added_to_pool(object)
        raise NotImplementedError
      end

      def object_removed_from_pool(object)
        raise NotImplementedError
      end
    end
  end
end