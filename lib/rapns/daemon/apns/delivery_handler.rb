module Rapns
  module Daemon
    module Apns
      class DeliveryHandler < Rapns::Daemon::DeliveryHandler

        attr_reader :name

        def initialize(name, host, port, certificate, password)
          @name = "DeliveryHandler:#{name}"
          @connection = Connection.new(@name, host, port, certificate, password)
          @connection.connect
        end

        def deliver(notification)
          Rapns::Daemon::Apns::Delivery.perform(@connection, notification)
        end

        def stopped
          @connection.close
        end
      end
    end
  end
end