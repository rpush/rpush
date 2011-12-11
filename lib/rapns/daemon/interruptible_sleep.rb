module Rapns
  module Daemon
    module InterruptibleSleep
      def interruptible_sleep(seconds)
        @_sleep_check, @_sleep_interrupt = IO.pipe
        IO.select([@_sleep_check], nil, nil, seconds)
      end

      def interrupt_sleep
        @_sleep_interrupt.close if @_sleep_interrupt
      end
    end
  end
end