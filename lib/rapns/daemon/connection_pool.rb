module Rapns
  module Daemon
    class ConnectionPool < Pool

      def claim_connection
        connection = nil
        begin
          connection = @queue.pop
          yield connection
        ensure
          @queue.push(connection) if connection
        end
        connection
      end

      protected

      def new_object_for_pool(i)
        Connection.new("Connection #{i}")
      end

      def object_added_to_pool(object)
        object.connect
      end

      def object_removed_from_pool(object)
        object.close
      end
    end
  end
end