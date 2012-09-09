module Rapns
  module Daemon
    module Gcm
      class DeliveryHandler < Rapns::Daemon::DeliveryHandler
        def initialize
          @http = Net::HTTP::Persistent.new('rapns')
        end

        def deliver(notification)
          Rapns::Daemon::Gcm::Delivery.perform(@http, notification)
        end

        def stopped
          @http.shutdown
        end
      end
    end
  end
end