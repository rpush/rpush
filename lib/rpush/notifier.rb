require 'socket'

module Rpush
  # This class notifies the sleeping Rpush Daemon that there are new Notifications to send,
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

  # Call this from a client application after saving a Notification to the database to wakeup the Rpush
  # Daemon to deliver the notification immediately.
  def self.wakeup
    notifier.notify
  end

  # Default notifier instance. This uses the :connect, :port values in Rpush.config.wakeup to connect to the
  # wakeup socket in the Rpush Daemon. It will fall back to :host, :port if :connect is not specified.
  def self.notifier
    unless @notifier
      if Rpush.config.wakeup
        @notifier = Notifier.new(Rpush.config.wakeup[:connect] || Rpush.config.wakeup[:host], Rpush.config.wakeup[:port])
      end
    end
    @notifier
  end
end
