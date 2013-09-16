module Rapns
  module Daemon
    class InterruptibleSleep

      def initialize
        @sleep_reader, @wake_writer = IO.pipe
      end

      # enable wake on receiving udp packets at the given address and port
      # this returns the host,port used by bind in case an ephemeral port
      # was indicated by specifying 0 as the port number.
      # @return [String,Integer] host,port of bound UDP socket.
      def enable_wake_on_udp(host, port)
        @udp_wakeup = UDPSocket.new
        @udp_wakeup.bind(host, port)
        @udp_wakeup.addr.values_at(3,1)
      end

      # wait for the given timeout in seconds, or data was written to the pipe
      # or the udp wakeup port if enabled.
      # @return [boolean] true if the sleep was interrupted, or false
      def sleep(timeout)
        read_ports = [@sleep_reader]
        read_ports << @udp_wakeup if @udp_wakeup
        rs, = IO.select(read_ports, nil, nil, timeout) rescue nil

        # consume all data on the readable io's so that our next call will wait for more data
        if rs && rs.include?(@sleep_reader)
          while true
            begin
              @sleep_reader.read_nonblock(1)
            rescue IO::WaitReadable
              break
            end
          end
        end

        if rs && rs.include?(@udp_wakeup)
          while true
            begin
              @udp_wakeup.recvmsg_nonblock
            rescue IO::WaitReadable
              break
            end
          end
        end

        !rs.nil? && rs.any?
      end

      # writing to the pipe will wake the sleeping thread
      def interrupt_sleep
        @wake_writer.write('.')
      end

      def close
        @sleep_reader.close rescue nil
        @wake_writer.close rescue nil
        @udp_wakeup.close if @udp_wakeup rescue nil
      end
    end
  end
end
