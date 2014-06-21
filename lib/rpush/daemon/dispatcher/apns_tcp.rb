module Rpush
  module Daemon
    module Dispatcher
      class ApnsTcp < Rpush::Daemon::Dispatcher::Tcp
        include Loggable

        SELECT_TIMEOUT = 10
        ERROR_TUPLE_BYTES = 6
        APNS_ERRORS = {
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

        def initialize(*args)
          super
          @dispatch_mutex = Mutex.new
          @stop_error_receiver = false
          start_error_receiver
        end

        def dispatch(payload)
          @dispatch_mutex.synchronize do
            @delivery_class.new(@app, connection, payload.batch).perform
            record_batch(payload.batch)
          end
        end

        def cleanup
          super
          @stop_error_receiver = true
          @error_receiver_thread.join if @error_receiver_thread
        end

        private

        def start_error_receiver
          @error_receiver_thread = Thread.new do
            while !@stop_error_receiver
              check_for_error
            end
          end
        end

        def delivered_buffer
          @delivered_buffer ||= RingBuffer.new(Rpush.config.batch_size * 10)
        end

        def record_batch(batch)
          batch.each_delivered do |notification|
            delivered_buffer << notification.id
          end
        end

        def check_for_error
          return unless connection.select(SELECT_TIMEOUT)

          tuple = connection.read(ERROR_TUPLE_BYTES)

          @dispatch_mutex.synchronize do
            if tuple
              _, code, notification_id = tuple.unpack('ccN')
              handle_error(code, notification_id)
            else
              handle_disconnect
            end

            begin
              log_error('Error received, reconnecting...')
              connection.reconnect
            ensure
              delivered_buffer.clear
            end
          end
        end

        def handle_disconnect
          log_error('The APNs disconnected without returning an error. Marking all notifications delivered via this connection as failed.')
          Rpush::Daemon.store.mark_ids_failed(delivered_buffer, nil, 'The APNs disconnected without returning an error. This may indicate you are using an invalid certificate.', Time.now)
        end

        def handle_error(code, notification_id)
          failed_pos = delivered_buffer.index(notification_id)
          description = APNS_ERRORS[code.to_i] || "Unknown error code #{code.inspect}. Possible Rpush bug?"
          Rpush::Daemon.store.mark_ids_failed([notification_id], code, description, Time.now)

          if failed_pos
            failed_ids = delivered_buffer[(failed_pos + 1)..-1]
            if failed_ids.size > 0
              Rpush::Daemon.store.mark_ids_retryable(failed_ids, Time.now)
            end
          elsif delivered_buffer.size > 0
            log_error("Delivery sequence unknown for notifications following #{notification_id}.")
          end
        end
      end
    end
  end
end
