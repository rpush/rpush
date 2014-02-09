module Rpush
  module Daemon
    module Apns
      class Delivery < Rpush::Daemon::Delivery
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

        def initialize(app, conneciton, notification, batch)
          @app = app
          @connection = conneciton
          @notification = notification
          @batch = batch
        end

        def perform
          begin
            @connection.write(@notification.to_binary)
            check_for_error if Rpush.config.check_for_errors
            mark_delivered
            log_info("#{@notification.id} sent to #{@notification.device_token}")
          rescue Rpush::DeliveryError, Rpush::Apns::DisconnectionError => error
            mark_failed(error.code, error.description)
            raise
          end
        end

        protected

        def check_for_error
          if @connection.select(SELECT_TIMEOUT)
            error = nil

            if tuple = @connection.read(ERROR_TUPLE_BYTES)
              _, code, notification_id = tuple.unpack("ccN")

              description = APN_ERRORS[code.to_i] || "Unknown error. Possible Rpush bug?"
              error = Rpush::DeliveryError.new(code, notification_id, description)
            else
              error = Rpush::Apns::DisconnectionError.new
            end

            begin
              log_error("Error received, reconnecting...")
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
