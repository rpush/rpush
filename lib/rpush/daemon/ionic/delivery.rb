module Rpush
  module Daemon
    module Ionic
      class Delivery < Rpush::Daemon::Delivery
        host = 'https://api.ionic.io'

        IONIC_URI = URI.parse("#{host}/push/notifications")

        def initialize(app, http, notification, batch)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
        end

        def perform
          handle_response(send_request)
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

        def send_request
          post = Net::HTTP::Post.new(IONIC_URI.path, 'Content-Type'  => 'application/json',
                                                     'Authorization' => "Bearer #{@app.auth_key}")
          post.body = @notification.as_json.to_json
          @http.request(IONIC_URI, post)
        end

        def handle_response(response)
          case response.code.to_i
          when 201
            created(response)
          when 400
            bad_request
          when 401
            unauthorized
          when 500
            internal_server_error(response)
          when 503
            service_unavailable(response)
          else
            fail Rpush::DeliveryError.new(response.code.to_i, @notification.id, Rpush::Daemon::HTTP_STATUS_CODES[response.code.to_i])
          end
        end

        def created(response)
          mark_delivered
          log_info("#{@notification.id} sent to #{@notification.registration_ids.join(', ')}")
        end

        def bad_request
          fail Rpush::DeliveryError.new(400, @notification.id, 'Ionic failed to parse the JSON request. Possibly an Rpush bug, please open an issue.')
        end

        def unauthorized
          fail Rpush::DeliveryError.new(401, @notification.id, 'Unauthorized, check your App auth_key.')
        end

        def internal_server_error(response)
          mark_retryable_exponential @notification
          log_warn("Ionic responded with an Internal Error. " + retry_message)
        end

        def service_unavailable(response)
          mark_retryable_exponential @notification
          log_warn("Ionic responded with an Service Unavailable Error. " + retry_message)
        end

        def retry_message
          "Notification #{@notification.id} will be retried after #{@notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')} (retry #{@notification.retries})."
        end

      end
    end
  end
end
