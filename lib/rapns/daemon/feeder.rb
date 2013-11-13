module Rapns
  module Daemon
    class Feeder
      extend Reflectable

      def self.start
        @stop = false

        if Rapns.config.embedded
          Thread.new { feed_forever }
        elsif Rapns.config.push
          enqueue_notifications
        else
          feed_forever
        end
      end

      def self.stop
        @stop = true
        interrupt_sleep
      end

      def self.interrupt_sleep
        interruptible_sleeper.interrupt_sleep
      end

      protected

      def self.feed_forever
        loop do
          enqueue_notifications
          interruptible_sleeper.sleep(Rapns.config.push_poll)
          break if stop?
        end
      end

      def self.stop?
        @stop
      end

      def self.enqueue_notifications
        begin
          idle = Rapns::Daemon::AppRunner.idle.map(&:app)
          return if idle.empty?
          notifications = Rapns::Daemon.store.deliverable_notifications(idle)
          Rapns::Daemon::AppRunner.enqueue(notifications)
        rescue StandardError => e
          Rapns.logger.error(e)
          reflect(:error, e)
        end
      end

      def self.interruptible_sleeper
        return @interruptible_sleeper if @interruptible_sleeper

        @interruptible_sleeper = InterruptibleSleep.new
        if Rapns.config.wakeup
          @interruptible_sleeper.enable_wake_on_udp Rapns.config.wakeup[:bind], Rapns.config.wakeup[:port]
        end

        @interruptible_sleeper
      end
    end
  end
end
