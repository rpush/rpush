module Rpush
  module Daemon
    class DispatcherLoop
      include Reflectable

      WAKEUP = :wakeup

      def initialize(queue, dispatcher)
        @queue = queue
        @dispatcher = dispatcher
      end

      def start
        @thread = Thread.new do
          loop do
            dispatch
            break if @stop
          end
        end
      end

      def stop
        @stop = true
      end

      def wakeup
        @queue.push(WAKEUP) if @thread
      end

      def wait
        @thread.join if @thread
        @dispatcher.cleanup
      end

      protected

      def dispatch
        notification, batch = @queue.pop
        return if notification == WAKEUP

        begin
          @dispatcher.dispatch(notification, batch)
        rescue StandardError => e
          Rpush.logger.error(e)
          reflect(:error, e)
        ensure
          batch.notification_dispatched
        end
      end
    end
  end
end
