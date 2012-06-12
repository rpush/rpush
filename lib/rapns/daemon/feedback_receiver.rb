module Rapns
  module Daemon
    class FeedbackReceiver
      extend InterruptibleSleep

      FEEDBACK_TUPLE_BYTES = 38

      def self.start(app, host, port, poll, certificate, password)
        @thread = Thread.new do
          loop do
            break if @stop
            check_for_feedback(app, host, port, certificate, password)
            interruptible_sleep poll
          end
        end
      end

      def self.stop
        @stop = true
        interrupt_sleep
        @thread.join if @thread
      end

      def self.check_for_feedback(app, host, port, certificate, password)
        connection = nil
        begin
          connection = Connection.new("FeedbackReceiver:#{app}", host, port, certificate, password)
          connection.connect

          while tuple = connection.read(FEEDBACK_TUPLE_BYTES)
            timestamp, device_token = parse_tuple(tuple)
            create_feedback(app, timestamp, device_token)
          end
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        ensure
          connection.close if connection
        end
      end

      protected

      def self.parse_tuple(tuple)
        failed_at, _, device_token = tuple.unpack("N1n1H*")
        [Time.at(failed_at).utc, device_token]
      end

      def self.create_feedback(app, failed_at, device_token)
        formatted_failed_at = failed_at.strftime("%Y-%m-%d %H:%M:%S UTC")
        Rapns::Daemon.logger.info("[FeedbackReceiver:#{app}] Delivery failed at #{formatted_failed_at} for #{device_token}")
        Rapns::Feedback.create!(:failed_at => failed_at, :device_token => device_token, :app => app)
      end
    end
  end
end