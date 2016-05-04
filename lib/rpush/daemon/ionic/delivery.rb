module Rpush
  module Daemon
    module Ionic
      class Delivery
        host = 'https://api.ionic.io'

        IONIC_URI = URI.parse("#{host}/push/notifications")

        def initialize(app, http, notification, batch)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
        end

        def perform
          post = Net::HTTP::Post.new(IONIC_URI.path, 'Content-Type'  => 'application/json',
                                                     'Authorization' => "Bearer #{@app.auth_key}")
          post.body = @notification.as_json.to_json
          @http.request(IONIC_URI, post)
        end

      end
    end
  end
end
