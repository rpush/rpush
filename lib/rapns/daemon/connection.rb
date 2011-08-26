module Rapns
  module Daemon
    class Connection
      class ConnectionError < Exception; end

      def connect
        @ssl_context = setup_ssl_context
        @tcp_socket, @ssl_socket = connect_socket
        setup_at_exit_hook
      end

      def write(data)
        retry_count = 0

        begin
          @ssl_socket.write(data)
          @ssl_socket.flush
        rescue Errno::EPIPE => e
          Rapns::Daemon.logger.warn("Lost connection to #{Rapns::Daemon.configuration.host}:#{Rapns::Daemon.configuration.port}, reconnecting...")
          @tcp_socket, @ssl_socket = connect_socket

          retry_count += 1

          if retry_count < 3
            sleep 1
            retry
          else
            raise ConnectionError, "Tried #{retry_count} times to reconnect but failed: #{e.inspect}"
          end
        end
      end

      protected

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
        Rapns::Daemon.logger.info("Connected to #{Rapns::Daemon.configuration.host}:#{Rapns::Daemon.configuration.port}")
        [tcp_socket, ssl_socket]
      end

      def setup_at_exit_hook
        Kernel.at_exit { shutdown_socket }
      end

      def shutdown_socket
        @ssl_socket.close if @ssl_socket
        @tcp_socket.close if @tcp_socket
      end
    end
  end
end