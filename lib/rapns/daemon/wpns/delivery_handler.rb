module Rapns
  module Daemon
    module Wpns
      class DeliveryHandler < Rapns::Daemon::DeliveryHandler
        def initialize(app)
          @app = app
          @http = Net::HTTP::Persistent.new('rapns')
        end

        def deliver(notification, batch)
          Rapns::Daemon::Wpns::Delivery.new(@app, @http, notification, batch).perform
        end

        def stopped
          @http.shutdown
        end

      end
    end
  end
end
