module Rpush
  module Daemon
    module Dispatcher
      class ApnsTcp < Rpush::Daemon::Dispatcher::Tcp
        include Loggable
        include Reflectable

        SELECT_TIMEOUT = 10
        ERROR_TUPLE_BYTES = 6
        APNS_ERRORS = {
          1 => 'Processing error',
          2 => 'Missing device token',
          3 => 'Missing topic',
          4 => 'Missing payload',
          5 => 'Missing token size',
          6 => 'Missing topic size',
          7 => 'Missing payload size',
          8 => 'Invalid token',
          255 => 'None (unknown error)'
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
          @stop_error_receiver = true
          super
          @error_receiver_thread.join if @error_receiver_thread
        end

        private

        def start_error_receiver
          @error_receiver_thread = Thread.new do
            check_for_error until @stop_error_receiver
            Rpush::Daemon.store.release_connection
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
          begin
            return unless connection.select(SELECT_TIMEOUT)
          rescue Errno::EBADF
            # Connection closed, daemon is shutting down.
            return
          end

          tuple = connection.read(ERROR_TUPLE_BYTES)
          @dispatch_mutex.synchronize { handle_error_response(tuple) }
        end

        def handle_error_response(tuple)
          if tuple
            _, code, notification_id = tuple.unpack('ccN')
            handle_error(code, notification_id)
          else
            handle_disconnect
          end

          log_warn('Reconnecting...')
          connection.reconnect
        ensure
          delivered_buffer.clear
        end

        def handle_disconnect
          if delivered_buffer.size == 0
            log_error("The APNs disconnected before any notifications could be delivered. This usually indicates you are using an invalid certificate.")
          else
            log_error("The APNs disconnected without returning an error. Marking #{delivered_buffer.size} notifications delivered via this connection as failed.")
            reason = 'The APNs disconnected without returning an error. This can indicate you are using an invalid certificate or a network event caused the connection to terminate.'
            Rpush::Daemon.store.mark_ids_failed(delivered_buffer, nil, reason, Time.now)
            delivered_buffer.each { |id| reflect(:notification_id_failed, @app, id, nil, reason) }
          end
        end

        def handle_error(code, notification_id)
          failed_pos = delivered_buffer.index(notification_id)
          description = APNS_ERRORS[code.to_i] || "Unknown error code #{code.inspect}. Possible Rpush bug?"
          log_error(description + " (#{code})")
          Rpush::Daemon.store.mark_ids_failed([notification_id], code, description, Time.now)
          reflect(:notification_id_failed, @app, notification_id, code, description)

          if failed_pos
            retry_ids = delivered_buffer[(failed_pos + 1)..-1]
            if retry_ids.size > 0
              now = Time.now
              Rpush::Daemon.store.mark_ids_retryable(retry_ids, now)
              retry_ids.each { |id| reflect(:notification_id_will_retry, @app, id, now) }
            end
          elsif delivered_buffer.size > 0
            log_error("Delivery sequence unknown for notifications following #{notification_id}.")
          end
        end
      end
    end
  end
end
