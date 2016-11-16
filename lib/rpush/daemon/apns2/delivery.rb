module Rpush
  module Daemon
    module Apns2
      # https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingwithAPNs.html

      HTTP2_HEADERS_KEY = 'headers'

      class Delivery < Rpush::Daemon::Delivery
        RETRYABLE_CODES = [ 429, 500, 503 ]

        def initialize(app, http2_client, batch, notification)
          @app = app
          @client = http2_client
          @batch = batch
          @notification = notification
          @response = OpenStruct.new
        end

        def perform
          do_async_post
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
        ######################################################################

        def handle_response
          code = @response.code
          case code
          when 200
            ok
          when *RETRYABLE_CODES
            service_unavailable
          else
            reflect(:notification_id_failed,
              @app,
              @notification.id, code,
              @response.failure_reason)
            fail Rpush::DeliveryError.new(@response.code,
              @notification.id, @response.failure_reason)
          end
        end

        def ok
          log_info("#{@notification.id} sent to #{@notification.device_token}")
          mark_delivered
        end

        def service_unavailable
          mark_retryable(@notification, Time.now + 10.seconds)
          # Logs should go last as soon as we need to initialize
          # retry time to display it in log
          failed_message_to_log
          retry_message_to_log
        end

        def do_async_post
          request = build_request
          http_request = @client.prepare_request(:post, request[:path],
            body:    request[:body],
            headers: request[:headers]
          )

          http_request.on(:headers) do |hdrs|
            @response.code = hdrs[':status'].to_i
          end

          http_request.on(:body_chunk) do |body_chunk|
            next unless body_chunk.present?

            @response.failure_reason = JSON.parse(body_chunk)['reason']
          end

          http_request.on(:close) { handle_response }

          @client.call_async(http_request)
          @client.join
        end

        def build_request
          {
            path:    "/3/device/#{@notification.device_token}",
            headers: prepare_headers,
            body:    prepare_body
          }
        end

        def prepare_body
          aps = {}

          primary_fields = [:alert, :badge, :sound, :category,
            'content-available', 'url-args']
          primary_fields.each do |primary_field|
            field_value = @notification.send(primary_field.to_s.underscore.to_sym)
            next unless field_value

            aps[primary_field] = field_value
          end

          hash = { aps: aps }
          hash.merge!(notification_data.except(HTTP2_HEADERS_KEY) || {})
          JSON.dump(hash).force_encoding(Encoding::BINARY)
        end

        def prepare_headers
          notification_data[HTTP2_HEADERS_KEY] || {}
        end

        def notification_data
          @notification.data || {}
        end

        def retry_message_to_log
          log_warn("Notification #{@notification.id} will be retried after "\
            "#{@notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')} "\
            "(retry #{@notification.retries}).")
        end

        def failed_message_to_log
          log_error("Notification #{@notification.id} failed, "\
            "#{@response.code}/#{@response.failure_reason}")
        end
      end
    end
  end
end
