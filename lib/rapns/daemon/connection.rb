module Rapns
  class DeliveryError < StandardError; end

  module Daemon
    class Connection
      class ConnectionError < StandardError; end

      CLOSE_CMD = 0x666
      SELECT_TIMEOUT = 0.5
      ERROR_PACKET_BYTES = 6
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

      def initialize(name, queue)
        @name = name
        @queue = queue
      end

      def connect
        @ssl_context = setup_ssl_context
        @tcp_socket, @ssl_socket = connect_socket

        @thread = Thread.new do
          loop do
            data = @queue.pop
            break if data == CLOSE_CMD
            write(data)
          end

          close_socket
        end
      end

      def close
        @queue.push(CLOSE_CMD)
        @thread.join if @thread
      end

      protected

      def write(data)
        retry_count = 0

        begin
          @ssl_socket.write(data)
          @ssl_socket.flush

          check_for_error
        rescue Errno::EPIPE => e
          Rapns::Daemon.logger.warn("[#{@name}] Lost connection to #{Rapns::Daemon.configuration.host}:#{Rapns::Daemon.configuration.port}, reconnecting...")
          @tcp_socket, @ssl_socket = connect_socket

          retry_count += 1

          if retry_count < 3
            sleep 1
            retry
          else
            raise ConnectionError, "#{@name} tried #{retry_count} times to reconnect but failed: #{e.inspect}"
          end
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        end
      end

      protected

      def check_for_error
        if IO.select([@ssl_socket], nil, nil, SELECT_TIMEOUT)
          if error = @ssl_socket.read(ERROR_PACKET_BYTES)
            cmd, status, notification_id = error.unpack("ccN")
            handle_error(status, notification_id) if cmd == 8 && status != 0
          end

          close_socket
          @tcp_socket, @ssl_socket = connect_socket
        end
      end

      # TODO: This is probably in the wrong place and should be handled by the Runner instead.
      def handle_error(status, notification_id)
        # Catch exceptions so they don't bubble up as we need to ensure the connection is closed after the error.
        begin
          description = APN_ERRORS[status] || "Unknown error. Possible rapns bug?"
          error = DeliveryError.new("Received APN error #{status} (#{description}) for notification #{notification_id}")
          Rapns::Daemon.logger.error(error)

          if notification = Rapns::Notification.find_by_id(notification_id)
            notification.delivered = false
            notification.delivered_at = nil
            notification.failed = true
            notification.failed_at = Time.now
            notification.error_code = status
            notification.error_description = description
            notification.save!(:validate => false)
          end
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        end
      end

      def setup_ssl_context
        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.key = OpenSSL::PKey::RSA.new(Rapns::Daemon.certificate.certificate, Rapns::Daemon.configuration.certificate_password)
        ssl_context.cert = OpenSSL::X509::Certificate.new(Rapns::Daemon.certificate.certificate)
        ssl_context
      end

      def connect_socket
        tcp_socket = TCPSocket.new(Rapns::Daemon.configuration.host, Rapns::Daemon.configuration.port)
        ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, @ssl_context)
        ssl_socket.sync = true
        ssl_socket.connect
        Rapns::Daemon.logger.info("[#{@name}] Connected to #{Rapns::Daemon.configuration.host}:#{Rapns::Daemon.configuration.port}")
        [tcp_socket, ssl_socket]
      end

      def close_socket
        @ssl_socket.close if @ssl_socket
        @tcp_socket.close if @tcp_socket
      end
    end
  end
end