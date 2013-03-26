module Rapns
  module Daemon
    module InterruptibleSleep
      def interruptible_sleep(seconds)
        @_sleep_check, @_sleep_interrupt = IO.pipe
        IO.select([@_sleep_check], nil, nil, seconds) rescue Errno::EINVAL
        @_sleep_check.close rescue IOError
        @_sleep_interrupt.close rescue IOError
      end

      def interrupt_sleep
        if @_sleep_interrupt
          @_sleep_interrupt.close rescue IOError
        end
      end
    end
  end
end
