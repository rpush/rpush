module Rapns
  module Daemon
    module Gcm
      class DeliveryHandler < Rapns::Daemon::DeliveryHandler
        include DatabaseReconnectable

        GCM_URI = URI.parse('https://android.googleapis.com/gcm/send')

        def initialize
          @http = Net::HTTP::Persistent.new('rapns')
        end

        def deliver(notification)
          response = post(notification)
          # CHECK RESPONSE CODES
          mark_notification_delivered(notification)
          # Rapns::Daemon.logger.info("[#{@name}] #{notification.id} sent to #{notification.device_token}")
        end

        def stopped
          @http.shutdown
        end

        protected

        def body(notification)
          body = {
            'registration_ids' => notification.registration_ids,
            'delay_while_idle' => notification.delay_while_idle,
            'data' => notification.data
          }

          if notification.collapse_key
            body['collapse_key'] = notification.collapse_key
            body['time_to_live'] = notification.expiry
          end

          body
        end

        def post(notification)
          post = Net::HTTP::Post.new(GCM_URI.path, initheader = {'Content-Type'  =>'application/json',
                                                                 'Authorization' => "key=#{notification.app.auth_key}"})
          post.body = body(notification).to_json
          @http.request(GCM_URI, post)
        end
      end
    end
  end
end