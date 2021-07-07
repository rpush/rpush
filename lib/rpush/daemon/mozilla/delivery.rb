module Rpush
  module Daemon
    module Mozilla
      class Delivery < Rpush::Daemon::Delivery
        include MultiJsonHelper

        host = 'https://updates.push.services.mozilla.com'
        URI = URI.parse("#{host}/wpush/v1")
        UNAVAILABLE_STATES = %w()
        INVALID_REGISTRATION_ID_STATES = %w()

        def initialize(app, http, notification, batch)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
        end

        def perform
          handle_response(do_post)
        rescue SocketError => error
          mark_retryable(@notification, Time.now + 10.seconds, error)
          raise
        rescue StandardError => error
          mark_failed(error)
          raise
        ensure
          @batch.notification_processed
        end

        protected

        def handle_response(response)
          case response.code.to_i
          when 201
            ok(response)
          else
            fail Rpush::DeliveryError.new(response.code.to_i, @notification.id, Rpush::Daemon::HTTP_STATUS_CODES[response.code.to_i])
          end
        end

        def ok(response)
          mark_delivered
          log_info("#{@notification.id} sent to #{@notification.registration_ids.join(', ')}")
        end

        def do_post
          post = Net::HTTP::Post.new("#{URI.path}/#{@notification.registration_ids.first}")
          post['TTL'] = @notification.expiry

          @http.request(URI, post)
        end
      end
    end
  end
end
