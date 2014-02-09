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

        def handle_failure(code, msg=nil)
          unless msg
            msg = if FAILURE_MESSAGES.key?(code)
              FAILURE_MESSAGES[code]
            else
              Rpush::Daemon::HTTP_STATUS_CODES[code]
            end
          end
          raise Rpush::DeliveryError.new(code, @notification.id, msg)
        end

        def ok(response)
          status = status_from_response(response)
          case status[:notification]
          when ["Received"]
            mark_delivered
            log_info("#{@notification.id} sent successfully")
          when ["QueueFull"]
            mark_retryable(@notification, Time.now + (60*10))
            log_warn("#{@notification.id} cannot be sent. The Queue is full.")
          when ["Suppressed"]
            handle_failure(200, "Notification was received but suppressed by the service.")
          end
        end

        def not_acceptable(response)
          retry_notification("Per-day throttling limit reached.")
        end

        def precondition_failed(response)
          retry_notification("Device unreachable.")
        end

        def service_unavailable(response)
          mark_retryable_exponential(@notification)
          log_warn("Service Unavailable. " + retry_message)
        end

        def retry_message
          "Notification #{@notification.id} will be retried after #{@notification.deliver_after.strftime("%Y-%m-%d %H:%M:%S")} (retry #{@notification.retries})."
        end

        def retry_notification(reason)
          deliver_after = Time.now + (60*60)
          mark_retryable(@notification, deliver_after)
          log_warn("#{reason} " + retry_message)
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
