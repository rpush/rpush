module Rpush
  module Daemon
    module Dispatcher
      class HmsHttp
        def initialize(app, delivery_class, token_provider:)
          @app = app
          @delivery_class = delivery_class
          @http = Net::HTTP::Persistent.new(name: 'rpush')
          @token_provider = token_provider
        end

        def dispatch(payload)
          @delivery_class.new(
            @app, @http, payload.notification, payload.batch, token_provider: @token_provider.new(@app)
          ).perform
        end

        def cleanup
          @http.shutdown
        end
      end
    end
  end
end
