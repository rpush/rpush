module Rapns
  module Daemon
    module Apns
      class DeliveryHandler < Rapns::Daemon::DeliveryHandler
        HOSTS = {
          :production  => ['gateway.push.apple.com', 2195],
          :development => ['gateway.sandbox.push.apple.com', 2195], # deprecated
          :sandbox     => ['gateway.sandbox.push.apple.com', 2195]
        }

        def initialize(app)
          @app = app
          host, port = HOSTS[@app.environment.to_sym]
          @connection = Connection.new(@app, host, port)
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
