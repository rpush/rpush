class PGError < StandardError; end unless defined?(PGError)
module PG
  class Error < StandardError; end unless defined?(::PG::Error)
end
class Mysql; class Error < StandardError; end; end unless defined?(Mysql)
module Mysql2; class Error < StandardError; end; end unless defined?(Mysql2)
module ActiveRecord
  class JDBCError < StandardError; end unless defined?(::ActiveRecord::JDBCError)
end

# :nocov:
unless defined?(::SQLite3::Exception)
  module SQLite3
    class Exception < StandardError; end
  end
end

module Rpush
  module Daemon
    module Store
      class ActiveRecord
        module Reconnectable
          ADAPTER_ERRORS = [
              ::ActiveRecord::ConnectionNotEstablished,
              ::ActiveRecord::ConnectionTimeoutError,
              ::ActiveRecord::JDBCError,
              ::ActiveRecord::StatementInvalid,
              Mysql::Error,
              Mysql2::Error,
              PG::Error,
              PGError,
              SQLite3::Exception
          ]

          def with_database_reconnect_and_retry
            ::ActiveRecord::Base.connection_pool.with_connection do
              yield
            end
          rescue *ADAPTER_ERRORS => e
            Rpush.logger.error(e)
            sleep_to_avoid_thrashing
            database_connection_lost
            retry
          end

          def database_connection_lost
            Rpush.logger.warn("Lost connection to database, reconnecting...")
            attempts = 0
            loop do
              begin
                Rpush.logger.warn("Attempt #{attempts += 1}")
                reconnect_database
                check_database_is_connected
                break
              rescue *ADAPTER_ERRORS => e
                Rpush.logger.error(e)
                sleep_to_avoid_thrashing
              end
            end
            Rpush.logger.warn("Database reconnected")
          end

          def reconnect_database
            clear_all_database_connections
            ::ActiveRecord::Base.establish_connection
          end

          # ActiveRecord::Base.clear_all_connections! was deprecated in Rails 7.1
          # and removed in 7.2; the connection handler has the method in every
          # supported version. From 7.1, calling it without a role is deprecated
          # (7.1) or means every role (7.2+), so ask for :all explicitly.
          def clear_all_database_connections
            handler = ::ActiveRecord::Base.connection_handler
            if ::ActiveRecord.version >= Gem::Version.new('7.1')
              handler.clear_all_connections!(:all)
            else
              handler.clear_all_connections!
            end
          end

          def check_database_is_connected
            # Simply asking the adapter for the connection state is not sufficient.
            Rpush::Client::ActiveRecord::Notification.exists?
          end

          def sleep_to_avoid_thrashing
            sleep 2
          end
        end
      end
    end
  end
end
