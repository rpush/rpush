module Rpush
  module Daemon
    module Apns2
      class Delivery < Rpush::Daemon::Delivery

        URLS = {
          production: 'https://api.push.apple.com:443',
          development: 'https://api.development.push.apple.com:443'
        }

        RETRYABLE_CODES = [ 429, 500, 503 ]

        DEFAULT_TIMEOUT = 60

        # While we don't use @batch here directly,
        # @batch instance variable is used in superclass methods
        def initialize(app, batch, notification)
          @app = app
          @batch = batch
          @notification = notification

          url = URLS[app.environment.to_sym]
          @client = NetHttp2::Client.new(url,
            ssl_context: ssl_context(app),
            connect_timeout: DEFAULT_TIMEOUT)
        end

        def perform
          response = do_post
          if response.ok?
            log_info("#{@notification.id} sent to #{@notification.device_token}")
            mark_delivered
            return
          end

          status_code = response.code
          failure_reason = response.failure_reason
          log_error("Notification #{@notification.id} failed, #{status_code}/#{failure_reason}")

          if RETRYABLE_CODES.include?(status_code)
            mark_retryable(@notification, Time.now + 10.seconds)
            log_warn(retry_message)
            return
          end

          mark_failed(failure_reason)
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

        def ssl_context(app)
          @ssl_context ||= begin
            ctx = OpenSSL::SSL::SSLContext.new
            begin
              p12      = OpenSSL::PKCS12.new(app.certificate, app.password)
              ctx.key  = p12.key
              ctx.cert = p12.certificate
            rescue OpenSSL::PKCS12::PKCS12Error
              ctx.key  = OpenSSL::PKey::RSA.new(app.certificate, app.password)
              ctx.cert = OpenSSL::X509::Certificate.new(app.certificate)
            end
            ctx
          end
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

        class Response
          attr_reader :code, :failure_reason

          def initialize(response_obj)
            @headers = response_obj.headers
            if response_obj.body.present?
              @body = JSON.parse(response_obj.body)
            end
          end

          def ok?
            code == 200
          end

          def code
            @headers[':status'].to_i
          end

          def failure_reason
            @body['reason'] if @body
          end
        end

        def retry_message
          "Notification #{@notification.id} will be retried after #{@notification.deliver_after.strftime('%Y-%m-%d %H:%M:%S')} (retry #{@notification.retries})."
        end
      end
    end
  end
end
