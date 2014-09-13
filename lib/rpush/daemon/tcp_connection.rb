module Rpush
  module Daemon
    class TcpConnectionError < StandardError; end

    class TcpConnection
      include Reflectable
      include Loggable

      attr_accessor :last_write

      def self.idle_period
        30.minutes
      end

      def initialize(app, host, port)
        @app = app
        @host = host
        @port = port
        @certificate = app.certificate
        @password = app.password
        written
      end

      def connect
        @ssl_context = setup_ssl_context
        @tcp_socket, @ssl_socket = connect_socket
      end

      def close
        @ssl_socket.close if @ssl_socket
        @tcp_socket.close if @tcp_socket
      rescue IOError # rubocop:disable HandleExceptions
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
        rescue Errno::EPIPE, Errno::ETIMEDOUT, OpenSSL::SSL::SSLError, IOError => e
          retry_count += 1

          if retry_count == 1
            log_error("Lost connection to #{@host}:#{@port} (#{e.class.name}), reconnecting...")
            reflect(:tcp_connection_lost, @app, e)
          end

          if retry_count <= 3
            reconnect
            sleep 1
            retry
          else
            raise TcpConnectionError, "#{@app.name} tried #{retry_count - 1} times to reconnect but failed (#{e.class.name})."
          end
        end
      end

      def reconnect
        close
        @tcp_socket, @ssl_socket = connect_socket
      end

      protected

      def reconnect_idle
        log_info("Idle period exceeded, reconnecting...")
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
        check_certificate_expiration

        tcp_socket = TCPSocket.new(@host, @port)
        tcp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
        tcp_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, @ssl_context)
        ssl_socket.sync = true
        ssl_socket.connect
        [tcp_socket, ssl_socket]
      rescue StandardError => error
        if error.message =~ /certificate revoked/i
          log_warn('Certificate has been revoked.')
          reflect(:ssl_certificate_revoked, @app, error)
        end
        raise
      end

      def check_certificate_expiration
        cert = @ssl_context.cert
        if certificate_expired?
          log_error(certificate_msg('expired'))
          fail Rpush::CertificateExpiredError.new(@app, cert.not_after)
        elsif certificate_expires_soon?
          log_warn(certificate_msg('will expire'))
          reflect(:ssl_certificate_will_expire, @app, cert.not_after)
        end
      end

      def certificate_msg(msg)
        time = @ssl_context.cert.not_after.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
        "Certificate #{msg} at #{time}."
      end

      def certificate_expired?
        @ssl_context.cert.not_after && @ssl_context.cert.not_after.utc < Time.now.utc
      end

      def certificate_expires_soon?
        @ssl_context.cert.not_after && @ssl_context.cert.not_after.utc < (Time.now + 1.month).utc
      end
    end
  end
end
