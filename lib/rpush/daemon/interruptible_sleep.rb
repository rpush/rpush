# frozen_string_literal: true

module Rpush
  module Daemon
    class InterruptibleSleep
      def sleep(duration)
        @thread = Thread.new { Kernel.sleep duration }
        Thread.pass

        begin
          @thread.join
        rescue StandardError
        ensure
          @thread = nil
        end
      end

      def stop
        @thread&.kill
      rescue StandardError
      ensure
        @thread = nil
      end
    end
  end
end
