module Rapns
  module Daemon
    module Apns
      class AppRunner < Rapns::Daemon::AppRunner
        ENVIRONMENTS = {
          :production => {
            :push     => ['gateway.push.apple.com', 2195],
            :feedback => ['feedback.push.apple.com', 2196]
          },
          :development => {
            :push      => ['gateway.sandbox.push.apple.com', 2195],
            :feedback  => ['feedback.sandbox.push.apple.com', 2196]
          }
        }

        protected

        def started
          poll = Rapns.config[:feedback_poll]
          host, port = ENVIRONMENTS[app.environment.to_sym][:feedback]
          @feedback_receiver = FeedbackReceiver.new(app, host, port, poll)
          @feedback_receiver.start
        end

        def stopped
          @feedback_receiver.stop if @feedback_receiver
        end

        def new_delivery_handler
          push_host, push_port = ENVIRONMENTS[app.environment.to_sym][:push]
          DeliveryHandler.new(app, push_host, push_port)
        end
      end
    end
  end
end
