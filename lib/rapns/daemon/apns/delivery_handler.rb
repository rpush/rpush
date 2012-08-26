module Rapns
  module Daemon
    module Apns
      class DeliveryHandler < Rapns::Daemon::DeliveryHandler
        SELECT_TIMEOUT = 0.2
        ERROR_TUPLE_BYTES = 6
        APN_ERRORS = {
          1 => "Processing error",
          2 => "Missing device token",
          3 => "Missing topic",
          4 => "Missing payload",
          5 => "Missing token size",
          6 => "Missing topic size",
          7 => "Missing payload size",
          8 => "Invalid token",
          255 => "None (unknown error)"
        }

        attr_reader :name
        attr_accessor :queue

        def initialize(name, host, port, certificate, password)
          @name = "DeliveryHandler:#{name}"
          @connection = Connection.new(@name, host, port, certificate, password)
          @connection.connect
        end

        protected

        def close
          @connection.close
        end

        def deliver(notification)
          begin
            @connection.write(notification.to_binary)
            check_for_error if Rapns::Daemon.config.check_for_errors

            with_database_reconnect_and_retry do
              notification.delivered = true
              notification.delivered_at = Time.now
              notification.save!(:validate => false)
            end

            Rapns::Daemon.logger.info("[#{@name}] #{notification.id} sent to #{notification.device_token}")
          rescue Rapns::DeliveryError, Rapns::DisconnectionError => error
            handle_delivery_error(notification, error.code, error.description)
            raise
          end
        end

        def check_for_error
          if @connection.select(SELECT_TIMEOUT)
            error = nil

            if tuple = @connection.read(ERROR_TUPLE_BYTES)
              cmd, code, notification_id = tuple.unpack("ccN")

              description = APN_ERRORS[code.to_i] || "Unknown error. Possible rapns bug?"
              error = Rapns::DeliveryError.new(code, notification_id, description)
            else
              error = Rapns::DisconnectionError.new
            end

            begin
              Rapns::Daemon.logger.error("[#{@name}] Error received, reconnecting...")
              @connection.reconnect
            ensure
              raise error if error
            end
          end
        end
      end
    end
  end
end