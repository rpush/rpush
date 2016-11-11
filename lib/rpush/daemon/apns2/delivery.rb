module Rpush
  module Daemon
    module Apns2
      # https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingwithAPNs.html
      class Delivery < Rpush::Daemon::Delivery
        RETRYABLE_CODES = [ 429, 500, 503 ]

        def initialize(app, http2_client, batch, notification)
          @app = app
          @client = http2_client
          @batch = batch
          @notification = notification
        end

        def perform
          handle_response(do_post)
        rescue SocketError => error
          mark_retryable(@notification, Time.now + 10.seconds, error)
          raise
        rescue StandardError => error
          mark_failed(error)
          reflect(:error, error)
          raise
        ensure
          @batch.notification_processed
        end

        protected
        ######################################################################

        def handle_response(response)
          code = response.code
          case code
          when 200
            ok(response)
          when *RETRYABLE_CODES
            service_unavailable(response)
          else
            reflect(:notification_id_failed,
              @app,
              @notification.id, code,
              response.failure_reason)
            fail Rpush::DeliveryError.new(response.code,
              @notification.id, response.failure_reason)
          end
        end

        def ok(response)
          log_info("#{@notification.id} sent to #{@notification.device_token}")
          mark_delivered
        end

        def service_unavailable(response)
          mark_retryable(@notification, Time.now + 10.seconds)
          # Logs should go last as soon as we need to initialize
          # retry time to display it in log
          failed_message_to_log(response)
          retry_message_to_log
        end

        def do_post
          request = prepare_request
          resp = @client.call(:post, request[:path],
            body:    request[:body],
            headers: request[:headers]
          )
          Response.new(resp)
        end

        def prepare_request
          {
            path: "/3/device/#{@notification.device_token}",
            headers: {},
            body: prepare_body(@notification)
          }
        end

        def prepare_body(notification)
          aps = {}

          primary_fields = [:alert, :badge, :sound, :category,
            'content-available', 'url-args']
          primary_fields.each do |primary_field|
            field_value = notification.send(primary_field.to_s.underscore.to_sym)
            next unless field_value

            aps[primary_field] = field_value
          end

          hash = { aps: aps }
          hash.merge!(notification.data || {})
          JSON.dump(hash).force_encoding(Encoding::BINARY)
        end

        def mark_retryable(notification, timer, error = nil)
          super
          reflect(:notification_id_will_retry, @app, notification.id, timer)
        end

        def retry_message_to_log
          log_warn("Notification #{@notification.id} will be retried after "\
            "#{@notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')} "\
            "(retry #{@notification.retries}).")
        end

        def failed_message_to_log(response)
          log_error("Notification #{@notification.id} failed, "\
            "#{response.code}/#{response.failure_reason}")
        end

        class Response
          attr_reader :code, :failure_reason

          def initialize(response_obj)
            @headers = response_obj.headers
            if response_obj.body.present?
              @body = JSON.parse(response_obj.body)
            end
          end

          def code
            @headers[':status'].to_i
          end

          def failure_reason
            @body['reason'] if @body
          end
        end
      end
    end
  end
end
