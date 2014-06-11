module Rpush
  module Daemon
    class DispatcherLoop
      include Reflectable

      WAKEUP = :wakeup

      def initialize(queue, dispatcher, batch_deliveries)
        @queue = queue
        @dispatcher = dispatcher
        @batch_deliveries = batch_deliveries
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
          Rpush.logger.error(e)
          reflect(:error, e)
        ensure
          batch.notification_dispatched
        end
      end
    end
  end
end
