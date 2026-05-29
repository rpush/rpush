module Rpush
  module Daemon
    module Store
      class ActiveRecord
        module Reconnectable
          adapter_errors = [
              ::ActiveRecord::ConnectionNotEstablished,
              ::ActiveRecord::ConnectionTimeoutError,
              ::ActiveRecord::StatementInvalid
          ]
          adapter_errors << ::ActiveRecord::JDBCError if defined?(::ActiveRecord::JDBCError)
          adapter_errors << Mysql::Error if defined?(Mysql::Error)
          adapter_errors << Mysql2::Error if defined?(Mysql2::Error)
          adapter_errors << PG::Error if defined?(PG::Error)
          adapter_errors << PGError if defined?(PGError)
          adapter_errors << SQLite3::Exception if defined?(SQLite3::Exception)
          ADAPTER_ERRORS = adapter_errors

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
            ::ActiveRecord::Base.clear_all_connections!
            ::ActiveRecord::Base.establish_connection
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
