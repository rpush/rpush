module Rapns
  module Daemon
    class FeedbackReceiver
      FEEDBACK_TUPLE_BYTES = 38

      def self.start
        @thread = Thread.new do
          loop do
            break if @stop
            check_for_feedback
            sleep 60
          end
        end
      end

      def self.stop
        @stop = true
        @thread.join if @thread
      end

      def self.check_for_feedback
        connection = nil
        begin
          connection = Connection.new("FeedbackReceiver", nil, nil)
          connection.connect

          while tuple = connection.read(FEEDBACK_TUPLE_BYTES)
            timestamp, device_token = parse_tuple(tuple)
            create_feedback(timestamp, device_token)
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
        [Time.at(failed_at), device_token]
      end

      def self.create_feedback(failed_at, device_token)
        Rapns::Daemon.logger.info("[FeedbackReceiver] Delivery failed at #{failed_at} for #{device_token}")
        Rapns::Feedback.create!(:failed_at => failed_at, :device_token => device_token)
      end
    end
  end
end