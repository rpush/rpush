module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter < AbstractAdapter
      class StatementPool < ConnectionAdapters::StatementPool
        def dealloc(key)
          @connection.query "DEALLOCATE #{key}" if connection_active?
        end

        def connection_active?
          @connection.status == PGconn::CONNECTION_OK
        rescue PGError
          false
        end
      end
    end
  end
end