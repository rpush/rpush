require 'socket'

module Rapns
  # This class notifies the sleeping Rapns Daemon that there are new Notifications to send,
  # and to interrupt its sleep to send them immediately. The purpose of this is to allow
  # much higher sleep times to reduce database polling activity.
  class Notifier
    def initialize(host, port)
      @host, @port = host, port
    end

    # notify the daemon that there is a Notification to send.
    def notify
      socket.write('x')
    end

    # @return [UDPSocket]
    def socket
      if @socket.nil?
        @socket = UDPSocket.new
        @socket.connect(@host, @port)
      end
      @socket
    end

    # close the udp socket
    def close
      if @socket
        @socket.close
        @socket = nil
      end
    end

  end
end
