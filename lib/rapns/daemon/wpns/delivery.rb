module Rapns
  module Daemon
    module Wpns
      class Delivery < Rapns::Daemon::Delivery
        attr_accessor :safe_mode_time, :end_safe_mode

        def initialize(app, http, notification, batch)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
          @end_safe_mode = nil
          @safe_mode_time = nil
        end

        def perform
          if @safe_mode_time == nil
            perform_unsafe
          else
            if Time.now < @safe_mode_time
              Rapns.logger.warn "Safe mode! you need to wait #{@safe_mode_time - Time.now}"
            else
              @safe_mode_time = nil
              @end_safe_mode = nil
              perform_unsafe
            end
          end
        end

        protected
        # Status codes.
        # http://msdn.microsoft.com/en-us/library/windowsphone/develop/ff941100%28v=vs.105%29.aspx
        def handle_response(res)
          case res.code.to_i
          when 200
            ok res
          when 400
            bad_request res
          when 401
            unauthorized res
          when 404
            not_found res
          when 405
            method_not_allowed res
          when 406
            not_acceptable res
          when 412
            precondition_failed res
          when 503
            service_unavailable res
          end
        end

        def ok(res)
          status = status_from_response res
          case status[:notification]
          when ["Received"]
            mark_delivered
            Rapns.logger.info "[#{@app.name}] #{@notification.id} sent successfully"
          when ["QueueFull"]
            mark_retryable @notification, Time.now + (60*10)
            Rapns.logger.warn "[#{@app.name}] #{@notification.id} cannot be sent. The Queue is full."
          when ["Supressed"]
            mark_delivered
            Rapns.logger.warn "[#{@app.name}] #{@notification.id} was received and dropped by the server."
          end

        end

        def bad_request(res)
          mark_failed 400, 'Bad XML or malformed notification URI'
          raise Rapns::DeliveryError.new(400, @notification.id,
                                         'Bad XML or malformed notification URI')
        end

        def unauthorized(res)
          mark_failed 401, "Unauthorized to send a notification to this app"
          raise Rapns::DeliveryError.new(401, @notification.id,
                                         "Unauthorized to send a notification to this app")
        end

        def not_found(res)
          # in this case we need to drop the notification since it's
          # not in the notification service
          mark_failed 404, 'Not found!'
          raise Rapns::DeliveryError.new(404, @notification.id,
                                         "Not found!")
        end

        def method_not_allowed(res)
          mark_failed 405, "No method allowed. This should be considered as a Rapns bug"
          raise Rapns::DeliveryError.new(405, @notification.id,
                                         "No method allowed. This should be considered as a Rapns bug")
        end

        def not_acceptable(res)
          # Now we can send notifications over an hour until tomorrow.
          Rapns.logger.warn "[#{@app.name}] #{@notification.id} Reached the per-day throttling limit for a subscription."
          @safe_mode_time = Time.now + (60*60*24)
          mark_failed 406, "Reached the per-day throttling limit for a subscription."
          raise Rapns::DeliveryError.new(406, @notification.id,
                                         "Reached the per-day throttling limit for a subscription.")
        end

        def precondition_failed(res)
          mark_failed 412, "Precondition Failed. Device is Disconnected for now."
          raise Rapns::DeliveryError.new(412, @notification.id,
                                         "Precondition Failed. Device is Disconnected for now.")
        end

        def service_unavailable(res)
          mark_failed 503, "Service unavailable."
          raise Rapns::DeliveryError.new(503, @notification.id,
                                         "Service unavailable.")
        end

        def do_post
          header = {
            "Content-Length" => notif_to_xml.length.to_s,
            "Content-Type" => "text/xml",
            "X-WindowsPhone-Target" => "toast",
            "X-NotificationClass" => '2'
          }
          post = Net::HTTP::Post.new(URI.parse(@notification.uri).path,initheader=header)
          post.body = notif_to_xml
          @http.request(URI.parse(@notification.uri), post)
        end

        private

        def status_from_response(res)
          {
            :notification         => res.to_hash["x-notificationstatus"],
            :notification_channel => res.to_hash["x-subscriptionstatus"],
            :device_connection    => res.to_hash["x-deviceconnectionstatus"]
          }
        end

        def perform_unsafe
          begin
            handle_response (do_post)
          rescue Rapns::DeliveryError => error
            mark_failed(error.code, error.description)
            raise
          end
        end

        def notif_to_xml
          @message = @notification.alert.gsub(/&/, "&amp;")
          @message = @notification.alert.gsub(/</, "&lt;")
          @message = @notification.alert.gsub(/>/, "&gt;")
          @message = @notification.alert.gsub(/'/, "&apos;")
          @message = @notification.alert.gsub(/"/, "&quot;")
          <<-EOF
<?xml version="1.0" encoding="utf-8"?>
    <wp:Notification xmlns:wp="WPNotification">
      <wp:Toast>
        <wp:Text1>#{@message}</wp:Text1>
      </wp:Toast>
    </wp:Notification>
          EOF
        end

      end
    end
  end
end
