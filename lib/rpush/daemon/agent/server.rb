module Rpush
  module Agent
    class Server
      HOST = '0.0.0.0'
      PORT = 42426
      RECV_BYTES = 1024

      def self.start
        @instance ||= new
        @instance.start
      end

      def self.stop
        @instance.stop if @instance
      end

      def initialize
        BasicSocket.do_not_reverse_lookup = true
      end

      def start
        @socket = UDPSocket.new
        @socket.bind(HOST, PORT)

        Thread.new do
          until @stop do
            begin
              data, addr = @socket.recvfrom_nonblock(RECV_BYTES)
            rescue IO::WaitReadable
              IO.select([@socket])
              retry
            end
          end
        end
      end

      def stop
        @stop = true
        @thread.join if @thread
        @socket.close if @socket
      end
    end
  end
end
