module Rpush
  module Daemon
    module Hms
      # https://developer.huawei.com/consumer/en/doc/development/HMS-References/push-sendapi
      class Delivery < Rpush::Daemon::Delivery
        # @param [Rpush::Client::Redis::Hms::Notification] notification
        # @param [Rpush::Client::Redis::Hms::App] app
        def initialize(app, http, notification, batch, token_provider: nil)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
          @token_provider = token_provider
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

        private

        def handle_response(response)
          @result = safely_parse(response.body)
          code = response.code.to_i
          case code
          when 200
            ok(response)
          when 500
            internal_server_error(response)
          when 502
            bad_gateway(response)
          when 503
            service_unavailable(response)
          else
            other_error(response)
          end
        end

        def handle_failure(code, msg = nil)
          unless msg
            msg = FAILURE_MESSAGES.key?(code) ? FAILURE_MESSAGES[code] : Rpush::Daemon::HTTP_STATUS_CODES[code]
          end
          fail Rpush::DeliveryError.new(code, @notification.id, msg)
        end

        def ok(response)
          case @result['code']
          when "80000000"
            mark_delivered
            log_info("#{@notification.id} sent successfully. RequestId: #{@result['requestId']}")
          else
            other_error(response)
          end
        end

        def do_post
          uri = URI.parse(@notification.uri)
          post = Net::HTTP::Post.new(
            uri.path,
            'Content-Type'  => 'application/json',
            'Authorization' => "Bearer #{@token_provider.token}"
          )
          post.body = @notification.as_json.to_json
          @http.request(uri, post)
        end

        def safely_parse(raw_json)
          JSON.parse(raw_json)
        rescue StandardError
          {
            "code" => "",
            "msg" => "",
            "requestId" => ""
          }
        end

        def retry_delivery(notification, response)
          time = deliver_after_header(response)
          if time
            mark_retryable(notification, time)
          else
            mark_retryable_exponential(notification)
          end
        end

        def deliver_after_header(response)
          Rpush::Daemon::RetryHeaderParser.parse(response.header['retry-after'])
        end

        def internal_server_error(response)
          retry_delivery(@notification, response)
          log_warn("HMS responded with an Internal Error. " + retry_message)
        end

        def bad_gateway(response)
          retry_delivery(@notification, response)
          log_warn("HMS responded with a Bad Gateway Error. " + retry_message)
        end

        def service_unavailable(response)
          retry_delivery(@notification, response)
          log_warn("HMS responded with a Service Unavailable Error. " + retry_message)
        end

        def other_error(response)
          begin
            reflect(:hms_deliver_failure, @app, @notification, @result.merge("http_code" => response.code.to_i))
          rescue StandardError => e
            log_error("Fail to run hms_deliver_failure callback for notification with id = #{@notification.id}. Result: #{@result}\\n#{e.backtrace[0..20].join('\n')}")
          end
          handle_failure(response.code.to_i, "#{@result['code']}: #{@result['msg']}. RequestId: #{@result['requestId']}")
        end

        def retry_message
          "Notification #{@notification.id} will be retried after #{@notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')} (retry #{@notification.retries})."
        end
      end
    end
  end
end
