module Rapns
  module Daemon
    module Apns
      class AppRunner < Rapns::Daemon::AppRunner
        protected

        def started
          unless Rapns.config.push
            poll = Rapns.config.feedback_poll
            @feedback_receiver = FeedbackReceiver.new(app, poll)
            @feedback_receiver.start
          end
        end

        def stopped
          @feedback_receiver.stop if @feedback_receiver
        end

        def new_delivery_handler
          DeliveryHandler.new(app)
        end
      end
    end
  end
end
