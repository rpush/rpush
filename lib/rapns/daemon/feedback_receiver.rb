module Rapns
  module Daemon
    class FeedbackReceiver
      include InterruptibleSleep

      FEEDBACK_TUPLE_BYTES = 38

      def initialize(name, host, port, poll, certificate, password)
        @name = name
        @host = host
        @port = port
        @poll = poll
        @certificate = certificate
        @password = password
      end

      def start
        @thread = Thread.new do
          loop do
            begin
              break if @stop
              check_for_feedback
            rescue OpenSSL::SSL::SSLError
              # stop the thread if there is an SSL error. Other errors might be recoverable,
              # and retrying later might make sense (for example, a network outage)
              @stop = true
              break
            rescue
              # error will be logged in check_for_feedback
            end
            interruptible_sleep @poll
          end
        end
      end

      def stop
        @stop = true
        interrupt_sleep
        @thread.join if @thread
      end

      def check_for_feedback
        connection = nil
        begin
          connection = Connection.new("FeedbackReceiver:#{@name}", @host, @port, @certificate, @password)
          connection.connect

          while tuple = connection.read(FEEDBACK_TUPLE_BYTES)
            timestamp, device_token = parse_tuple(tuple)
            create_feedback(timestamp, device_token)
          end
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
          raise
        ensure
          connection.close if connection
        end
      end

      protected

      def parse_tuple(tuple)
        failed_at, _, device_token = tuple.unpack("N1n1H*")
        [Time.at(failed_at).utc, device_token]
      end

      def create_feedback(failed_at, device_token)
        formatted_failed_at = failed_at.strftime("%Y-%m-%d %H:%M:%S UTC")
        Rapns::Daemon.logger.info("[FeedbackReceiver:#{@name}] Delivery failed at #{formatted_failed_at} for #{device_token}")
        Rapns::Feedback.create!(:failed_at => failed_at, :device_token => device_token, :app => @name)
      end
    end
  end
end