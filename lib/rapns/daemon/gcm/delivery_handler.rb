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
        end

        def stopped
          @http.shutdown
        end

        protected

        def body(notification)
          {
            'registration_ids' => notification.apps,
            'collapse_key' => notification.collapse_key,
            'delay_while_idle' => notification.delay_while_idle,
            'time_to_live' => notification.expiry,
            'data' => {

            }
          }
        end

        def post(notification)
          post = Net::HTTP::Post.new(GCM_URI.path, initheader = {'Content-Type' =>'application/json',
                                                  'Authorization' => notification.auth_key})
          post.set_form_data(body(notification))
          @http.request(GCM_URI, post)
        end
      end
    end
  end
end