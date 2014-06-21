module Rpush
  module Daemon
    class DispatcherLoop
      include Reflectable
      include Loggable

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

          Rpush::Daemon.store.release_connection
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
        payload = @queue.pop
        return if payload == WAKEUP

        begin
          @dispatcher.dispatch(payload)
        rescue StandardError => e
          log_error(e)
          reflect(:error, e)
        end
      end
    end
  end
end
