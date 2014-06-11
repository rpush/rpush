module Rpush
  module Daemon
    module Dispatcher
      class Tcp
        def initialize(app, delivery_class, options = {})
          @app = app
          @delivery_class = delivery_class
          @host, @port = options[:host].call(@app)
        end

        def dispatch(payload)
          @delivery_class.new(@app, connection, payload.notification, payload.batch).perform
        end

        def cleanup
          @connection.close if @connection
        end

        protected

        def connection
          return @connection if defined? @connection
          connection = Rpush::Daemon::TcpConnection.new(@app, @host, @port)
          connection.connect
          @connection = connection
        end
      end
    end
  end
end
