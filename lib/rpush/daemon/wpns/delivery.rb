module Rpush
  module Daemon
    module Wpns

      # http://msdn.microsoft.com/en-us/library/windowsphone/develop/ff941100%28v=vs.105%29.aspx
      class Delivery < Rpush::Daemon::Delivery

        FAILURE_MESSAGES = {
          400 => 'Bad XML or malformed notification URI.',
          401 => 'Unauthorized to send a notification to this app.'
        }

        def initialize(app, http, notification, batch)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
        end

        def perform
          begin
            handle_response(do_post)
          rescue Rpush::DeliveryError => error
            mark_failed(error.code, error.description)
            raise
          end
        end

        private

        def handle_response(response)
          code = response.code.to_i
          case code
          when 200
            ok(response)
          when 406
            not_acceptable(response)
          when 412
            precondition_failed(response)
          when 503
            service_unavailable(response)
          else
            handle_failure(code)
          end
        end

        def handle_failure(code)
          msg = if FAILURE_MESSAGES.key?(code)
            FAILURE_MESSAGES[code]
          else
            Rpush::Daemon::HTTP_STATUS_CODES[code]
          end
          raise Rpush::DeliveryError.new(code, @notification.id, msg)
        end

        def ok(response)
          status = status_from_response(response)
          case status[:notification]
          when ["Received"]
            mark_delivered
            Rpush.logger.info "[#{@app.name}] #{@notification.id} sent successfully"
          when ["QueueFull"]
            mark_retryable(@notification, Time.now + (60*10))
            Rpush.logger.warn "[#{@app.name}] #{@notification.id} cannot be sent. The Queue is full."
          when ["Suppressed"]
            mark_delivered
            # TODO: Dropped by device or server?
            Rpush.logger.warn "[#{@app.name}] #{@notification.id} was received and dropped by the server."
          end
        end

        def not_acceptable(response)
          # Per-day throttling limit reached. Retry the notification in 1 hour.
          deliver_after = Time.now + (60*60)
          mark_retryable(@notification, deliver_after)
          Rpush.logger.warn("[#{@app.name}] #{@notification.id} Reached the per-day throttling limit. Notification will be retried after #{deliver_after.strftime("%Y-%m-%d %H:%M:%S")}.")
        end

        def precondition_failed(response)
          # TODO: Retry after 1 hour. Fail after 24 hours.
          deliver_after = Time.now + (60*60)
          mark_retryable(@notification, deliver_after)
          Rpush.logger.warn("[#{@app.name}] #{@notification.id} Device unreachable. Notification will be retried after #{deliver_after.strftime("%Y-%m-%d %H:%M:%S")}.")
        end

        def service_unavailable(response)
          mark_retryable_exponential(@notification)
          Rpush.logger.warn("...")
        end

        def do_post
          body = notification_to_xml
          header = {
            "Content-Length" => body.length.to_s,
            "Content-Type" => "text/xml",
            "X-WindowsPhone-Target" => "toast",
            "X-NotificationClass" => '2'
          }
          post = Net::HTTP::Post.new(URI.parse(@notification.uri).path, initheader=header)
          post.body = body
          @http.request(URI.parse(@notification.uri), post)
        end

        def status_from_response(response)
          headers = response.to_hash
          {
            notification:         headers["x-notificationstatus"],
            notification_channel: headers["x-subscriptionstatus"],
            device_connection:    headers["x-deviceconnectionstatus"]
          }
        end

        def notification_to_xml
          msg = @notification.alert.gsub(/&/, "&amp;").gsub(/</, "&lt;") \
            .gsub(/>/, "&gt;").gsub(/'/, "&apos;").gsub(/"/, "&quot;")
          <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<wp:Notification xmlns:wp="WPNotification">
  <wp:Toast>
    <wp:Text1>#{msg}</wp:Text1>
  </wp:Toast>
</wp:Notification>
          EOF
        end
      end
    end
  end
end
