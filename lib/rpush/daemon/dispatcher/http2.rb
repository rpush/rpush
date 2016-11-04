module Rpush
  module Daemon
    module Dispatcher
      class Http2
        def initialize(app, delivery_class, _options = {})
          @app = app
          @delivery_class = delivery_class
        end

        def dispatch(payload)
          @delivery_class.new(@app, payload.batch, payload.notification).perform
        end

        def cleanup
        end
      end
    end
  end
end
