module Rpush
  module Daemon
    class Feeder
      extend Reflectable

      def self.start
        @stop = false

        if Rpush.config.embedded
          @thread = Thread.new { feed_forever }
        elsif Rpush.config.push
          enqueue_notifications
        else
          feed_forever
        end
      end

      def self.stop
        @should_stop = true
        interruptible_sleeper.stop
        @thread.join if @thread
        @interruptible_sleeper = nil
      end

      class << self
        attr_reader :should_stop
      end

      def self.feed_forever
        loop do
          enqueue_notifications
          interruptible_sleeper.sleep
          break if should_stop
        end

        Rpush::Daemon.store.release_connection
      end

      def self.enqueue_notifications
        # TODO: Worker modle is broken for batch APNS.
        batch_size = Rpush.config.batch_size - Rpush::Daemon::AppRunner.cumulative_queue_size
        return if batch_size <= 0
        notifications = Rpush::Daemon.store.deliverable_notifications(batch_size)
        Rpush::Daemon::AppRunner.enqueue(notifications)
      rescue StandardError => e
        Rpush.logger.error(e)
        reflect(:error, e)
      end

      def self.interruptible_sleeper
        return @interruptible_sleeper if @interruptible_sleeper
        @interruptible_sleeper = InterruptibleSleep.new(Rpush.config.push_poll)
        @interruptible_sleeper.start
        @interruptible_sleeper
      end
    end
  end
end
