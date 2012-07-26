module Rapns
  module Daemon
    module Apns
      class AppRunner < Rapns::Daemon::AppRunner
        def initialize(app, push_host, push_port, feedback_host, feedback_port, feedback_poll)
          self.app = app
          @push_host = push_host
          @push_port = push_port
          @feedback_host = feedback_host
          @feedback_port = feedback_port
          @feedback_poll = feedback_poll
        end

        def start
          super

          @feedback_receiver = FeedbackReceiver.new(app.key, @feedback_host, @feedback_port,
                                                    @feedback_poll, app.certificate, app.password)
          @feedback_receiver.start
        end

        def stop
          super

          @feedback_receiver.stop if @feedback_receiver
        end

        protected

        def start_handler
          handler = DeliveryHandler.new(queue, app.key, @push_host, @push_port, app.certificate, app.password)
          handler.start
          handler
        end
      end
    end
  end
end