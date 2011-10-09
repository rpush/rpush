module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter < AbstractAdapter
      def clear_cache!
        @statements.each_value do |value|
          @connection.query "DEALLOCATE #{value}" if active?
        end
        @statements.clear
      end
    end
  end
end