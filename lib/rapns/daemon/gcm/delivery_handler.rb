module Rapns
  module Daemon
    module Gcm
      class DeliveryHandler < Rapns::Daemon::DeliveryHandler

        GCM_URI = URI.parse('https://android.googleapis.com/gcm/send')

        def initialize
          @http = Net::HTTP::Persistent.new('rapns')
        end

        def deliver(notification)
          response = post(notification)
          STDERR.puts response.body
          # CHECK RESPONSE CODES
          mark_notification_delivered(notification)
          # Rapns::Daemon.logger.info("[#{@name}] #{notification.id} sent to #{notification.device_token}")
        end

        def stopped
          @http.shutdown
        end

        protected

        def post(notification)
          post = Net::HTTP::Post.new(GCM_URI.path, initheader = {'Content-Type'  =>'application/json',
                                                                 'Authorization' => "key=#{notification.app.auth_key}"})
          post.body = notification.as_json.to_json
          @http.request(GCM_URI, post)
        end
      end
    end
  end
end