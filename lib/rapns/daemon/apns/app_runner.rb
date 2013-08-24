module Rapns
  module Daemon
    module Apns
      class AppRunner < Rapns::Daemon::AppRunner
        include Reflectable

        protected

        def before_start
          check_certificate_expiration
        end

        def after_start
          unless Rapns.config.push
            poll = Rapns.config.feedback_poll
            @feedback_receiver = FeedbackReceiver.new(app, poll)
            @feedback_receiver.start
          end
        end

        def after_stop
          @feedback_receiver.stop if @feedback_receiver
        end

        def new_delivery_handler
          DeliveryHandler.new(app)
        end

        def check_certificate_expiration
          cert = OpenSSL::X509::Certificate.new(app.certificate)

          if cert.not_after
            if cert.not_after < Time.now.utc
              Rapns.logger.error("[#{app.name}] Certificate expired at #{cert.not_after.inspect}.")
              raise Rapns::Apns::CertificateExpiredError.new(app, cert.not_after)
            elsif cert.not_after < (Time.now + 1.month).utc
              Rapns.logger.warn("[#{app.name}] Certificate will expire at #{cert.not_after.inspect}.")
              reflect(:apns_certificate_will_expire, app, cert.not_after)
            end
          end
        end
      end
    end
  end
end
