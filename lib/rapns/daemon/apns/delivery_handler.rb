module Rapns
  module Daemon
    module Apns
      class DeliveryHandler < Rapns::Daemon::DeliveryHandler
        def initialize(app, host, port)
          @app = app
          @connection = Connection.new(@app.name, host, port, @app.certificate, @app.password)
          @connection.connect
        end

        def deliver(notification)
          Rapns::Daemon::Apns::Delivery.perform(@app, @connection, notification)
        end

        def stopped
          @connection.close
        end
      end
    end
  end
end
