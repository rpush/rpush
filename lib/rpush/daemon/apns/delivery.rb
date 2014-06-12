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

        def initialize(app, connection, batch)
          @app = app
          @connection = connection
          @batch = batch
        end

        def perform
          @connection.write(batch_to_binary)
          check_for_error if Rpush.config.check_for_errors
          mark_batch_delivered
          describe_deliveries
        rescue StandardError => error
          mark_batch_failed(error)
          raise
        ensure
          @batch.all_processed
        end

        protected

        def batch_to_binary
          payload = ""
          @batch.each_notification do |notification|
            payload << notification.to_binary
          end
          payload
        end

        def describe_deliveries
          @batch.each_notification do |notification|
            log_info("#{notification.id} sent to #{notification.device_token}")
          end
        end

        def check_for_error
          return unless @connection.select(SELECT_TIMEOUT)

          error = nil
          tuple = @connection.read(ERROR_TUPLE_BYTES)

          if tuple
            _, code, notification_id = tuple.unpack("ccN")

            description = APN_ERRORS[code.to_i] || "Unknown error. Possible Rpush bug?"
            error = Rpush::DeliveryError.new(code, notification_id, description)
          else
            error = Rpush::DisconnectionError.new("The APNs disconnected without returning an error. This may indicate you are using an invalid certificate for the host.")
          end

          begin
            log_error("Error received, reconnecting...")
            @connection.reconnect
          ensure
            fail error if error
          end
        end
      end
    end
  end
end
