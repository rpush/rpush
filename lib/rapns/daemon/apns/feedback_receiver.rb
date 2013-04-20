module Rapns
  module Daemon
    module Apns
      class FeedbackReceiver
        include Reflectable
        include InterruptibleSleep

        FEEDBACK_TUPLE_BYTES = 38
        HOSTS = {
          :production  => ['feedback.push.apple.com', 2196],
          :development => ['feedback.sandbox.push.apple.com', 2196], # deprecated
          :sandbox     => ['feedback.sandbox.push.apple.com', 2196]
        }

        def initialize(app, poll)
          @app = app
          @host, @port = HOSTS[@app.environment.to_sym]
          @poll = poll
          @certificate = app.certificate
          @password = app.password
        end

        def start
          @thread = Thread.new do
            loop do
              break if @stop
              check_for_feedback
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
            connection = Connection.new(@app, @host, @port)
            connection.connect

            while tuple = connection.read(FEEDBACK_TUPLE_BYTES)
              timestamp, device_token = parse_tuple(tuple)
              create_feedback(timestamp, device_token)
            end
          rescue StandardError => e
            Rapns.logger.error(e)
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
          Rapns.logger.info("[#{@app.name}] [FeedbackReceiver] Delivery failed at #{formatted_failed_at} for #{device_token}.")

          feedback = Rapns::Daemon.store.create_apns_feedback(failed_at, device_token, @app)
          reflect(:apns_feedback, feedback)

          # Deprecated.
          begin
            Rapns.config.apns_feedback_callback.call(feedback) if Rapns.config.apns_feedback_callback
          rescue StandardError => e
            Rapns.logger.error(e)
          end
        end
      end
    end
  end
end
