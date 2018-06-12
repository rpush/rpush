module Rpush
  module Daemon
    module Dispatcher
      class Apnsp8Http2

        URLS = {
          production: 'https://api.push.apple.com',
          development: 'https://api.development.push.apple.com'
        }

        DEFAULT_TIMEOUT = 60

        def initialize(app, delivery_class, _options = {})
          @app = app
          @delivery_class = delivery_class

          url = URLS[app.environment.to_sym]
          @client = NetHttp2::Client.new(url, connect_timeout: DEFAULT_TIMEOUT)
          @token_provider = Rpush::Daemon::Apnsp8::Token.new(@app)
        end

        def dispatch(payload)

          @delivery_class.new(@app, @client, @token_provider, payload.batch).perform
        end

        def cleanup
          @client.close
        end
      end
    end
  end
end
