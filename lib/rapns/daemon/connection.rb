module Rapns
  module Daemon
    class ConnectionError < StandardError; end

    class Connection
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

      def initialize(name)
        @name = name
      end

      def connect
        @ssl_context = setup_ssl_context
        @tcp_socket, @ssl_socket = connect_socket
      end

      def close
        @ssl_socket.close if @ssl_socket
        @tcp_socket.close if @tcp_socket
      end

      def write(data)
        retry_count = 0

        begin
          @ssl_socket.write(data)
          @ssl_socket.flush

          check_for_error
        rescue Errno::EPIPE => e
          Rapns::Daemon.logger.error("[#{@name}] Lost connection to #{Rapns::Daemon.configuration.host}:#{Rapns::Daemon.configuration.port}, reconnecting...")
          @tcp_socket, @ssl_socket = connect_socket

          retry_count += 1

          if retry_count < 3
            sleep 1
            retry
          else
            raise ConnectionError, "#{@name} tried #{retry_count} times to reconnect but failed: #{e.inspect}"
          end
        end
      end

      protected

      def check_for_error
        if IO.select([@ssl_socket], nil, nil, SELECT_TIMEOUT)
          delivery_error = nil

          if error = @ssl_socket.read(ERROR_PACKET_BYTES)
            cmd, status, notification_id = error.unpack("ccN")

            if cmd == 8 && status != 0
              description = APN_ERRORS[status] || "Unknown error. Possible rapns bug?"
              delivery_error = Rapns::DeliveryError.new(status, description, notification_id)
            end
          end

          begin
            Rapns::Daemon.logger.error("[#{@name}] Error received, reconnecting...")
            close
            @tcp_socket, @ssl_socket = connect_socket
          ensure
            raise delivery_error if delivery_error
          end
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
        tcp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
        tcp_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, @ssl_context)
        ssl_socket.sync = true
        ssl_socket.connect
        Rapns::Daemon.logger.info("[#{@name}] Connected to #{Rapns::Daemon.configuration.host}:#{Rapns::Daemon.configuration.port}")
        [tcp_socket, ssl_socket]
      end
    end
  end
end