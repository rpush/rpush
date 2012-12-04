module Rapns
  module Daemon
    module Apns
      class ConnectionError < StandardError; end

      class Connection
        attr_accessor :last_write

        def self.idle_period
          30.minutes
        end

        def initialize(name, host, port, certificate, password)
          @name = name
          @host = host
          @port = port
          @certificate = certificate
          @password = password
          written
        end

        def connect
          @ssl_context = setup_ssl_context
          @tcp_socket, @ssl_socket = connect_socket
        end

        def close
          begin
            @ssl_socket.close if @ssl_socket
            @tcp_socket.close if @tcp_socket
          rescue IOError
          end
        end

        def read(num_bytes)
          @ssl_socket.read(num_bytes)
        end

        def select(timeout)
          IO.select([@ssl_socket], nil, nil, timeout)
        end

        def write(data)
          reconnect_idle if idle_period_exceeded?

          retry_count = 0

          begin
            write_data(data)
          rescue Errno::EPIPE, Errno::ETIMEDOUT, OpenSSL::SSL::SSLError => e
            retry_count += 1;

            if retry_count == 1
              Rapns::Daemon.logger.error("[#{@name}] Lost connection to #{@host}:#{@port} (#{e.class.name}), reconnecting...")
            end

            if retry_count <= 3
              reconnect
              sleep 1
              retry
            else
              raise ConnectionError, "#{@name} tried #{retry_count-1} times to reconnect but failed (#{e.class.name})."
            end
          end
        end

        def reconnect
          close
          @tcp_socket, @ssl_socket = connect_socket
        end

        protected

        def reconnect_idle
          Rapns::Daemon.logger.info("[#{@name}] Idle period exceeded, reconnecting...")
          reconnect
        end

        def idle_period_exceeded?
          Time.now - last_write > self.class.idle_period
        end

        def write_data(data)
          @ssl_socket.write(data)
          @ssl_socket.flush
          written
        end

        def written
          self.last_write = Time.now
        end

        def setup_ssl_context
          ssl_context = OpenSSL::SSL::SSLContext.new
          ssl_context.key = OpenSSL::PKey::RSA.new(@certificate, @password)
          ssl_context.cert = OpenSSL::X509::Certificate.new(@certificate)
          ssl_context
        end

        def connect_socket
          tcp_socket = TCPSocket.new(@host, @port)
          tcp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
          tcp_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
          ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, @ssl_context)
          ssl_socket.sync = true
          ssl_socket.connect
          Rapns::Daemon.logger.info("[#{@name}] Connected to #{@host}:#{@port}")
          [tcp_socket, ssl_socket]
        end
      end
    end
  end
end