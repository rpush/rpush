module Rpush
  module Daemon
    class Feeder
      extend Reflectable

      def self.start(push_mode = false)
        self.should_stop = false

        @thread = Thread.new do
          push_mode ? feed_all : feed_forever
          Rpush::Daemon.store.release_connection
        end

        @thread.join
      end

      def self.stop
        self.should_stop = true
        interruptible_sleeper.stop
        @thread.join if @thread
      end

      def self.wakeup
        interruptible_sleeper.wakeup
      end

      class << self
        attr_accessor :should_stop
      end

      def self.feed_all
        enqueue_notifications until Rpush::Daemon.store.pending_delivery_count == 0
      end

      def self.feed_forever
        loop do
          enqueue_notifications
          interruptible_sleeper.sleep
          break if should_stop
        end
      end

      def self.enqueue_notifications
        batch_size = Rpush.config.batch_size - Rpush::Daemon::AppRunner.total_queued
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
