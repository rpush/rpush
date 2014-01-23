module Rapns
  module Daemon
    module Adm
      # https://developer.amazon.com/sdk/adm/sending-message.html
      class Delivery < Rapns::Daemon::Delivery
        include Rapns::MultiJsonHelper

        # Oauth2.0 token endpoint. This endpoint is used to request authorization tokens.
        AMAZON_TOKEN_URI = URI.parse('https://api.amazon.com/auth/O2/token')

        # ADM services endpoint. This endpoint is used to perform ADM requests.
        AMAZON_ADM_URL = 'https://api.amazon.com/messaging/registrations/%s/messages'

        # Data used to request authorization tokens.
        ACCESS_TOKEN_REQUEST_DATA = {"grant_type" => "client_credentials", "scope" => "messaging:push"}

        def initialize(app, http, notification, batch)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
          @sent_registration_ids = []
          @failed_registration_ids = {}
        end

        def perform
          begin
            @notification.registration_ids.each do |registration_id|
              handle_response(do_post(registration_id), registration_id)
            end

            if(@sent_registration_ids.empty?)
              raise Rapns::DeliveryError.new(nil, @notification.id, describe_errors)
            else
              unless(@failed_registration_ids.empty?)
                @notification.error_description = describe_errors
                Rapns::Daemon.store.update_notification(@notification)
              end

              mark_delivered
            end
          rescue Rapns::RetryableError => error
            handle_retryable(error)
          rescue Rapns::TooManyRequestsError => error
            handle_too_many_requests(error)
          rescue Rapns::DeliveryError => error
            mark_failed(error.code, error.description)
            raise
          end
        end

        protected

        def handle_response(response, current_registration_id)
          case response.code.to_i
          when 200
            ok(response, current_registration_id)
          when 400
            bad_request(response, current_registration_id)
          when 401
            unauthorized(response)
          when 429
            too_many_requests(response)
          when 500
            internal_server_error(response, current_registration_id)
          when 503
            service_unavailable(response)
          else
            raise Rapns::DeliveryError.new(response.code, @notification.id, Rapns::Daemon::HTTP_STATUS_CODES[response.code.to_i])
          end
        end

        def ok(response, current_registration_id)
          response_body = multi_json_load(response.body)

          if(response_body.has_key?('registrationID'))
            @sent_registration_ids << response_body['registrationID']
            Rapns.logger.info("[#{@app.name}] #{@notification.id} sent to #{response_body['registrationID']}")
          end

          if(current_registration_id != response_body['registrationID'])
            reflect(:adm_canonical_id, current_registration_id, response_body['registrationID'])
          end
        end

        def handle_retryable(error)
          case error.code
          when 401
            # clear app access_token so a new one is fetched
            @notification.app.access_token = nil
            get_access_token
            mark_retryable(@notification, Time.now) if @notification.app.access_token
          when 503
            retry_delivery(@notification, error.response)
            Rapns.logger.warn("[#{@app.name}] ADM responded with an Service Unavailable Error. " + retry_message)
          end
        end

        def handle_too_many_requests(error)
          if(@sent_registration_ids.empty?)
            # none sent yet, just resend after the specified retry-after response.header
            retry_delivery(@notification, error.response)
          else
            # save unsent registration ids
            unsent_registration_ids = @notification.registration_ids.select { |reg_id| !@sent_registration_ids.include?(reg_id) }

            # update the current notification so it only contains the sent reg ids
            @notification.registration_ids.reject! { |reg_id| !@sent_registration_ids.include?(reg_id) }

            Rapns::Daemon.store.update_notification(@notification)

            # create a new notification with the remaining unsent reg ids
            create_new_notification(error.response, unsent_registration_ids)

            # mark the current notification as sent
            mark_delivered
          end
        end

        def bad_request(response, current_registration_id)
          response_body = multi_json_load(response.body)

          if(response_body.has_key?('reason'))
            Rapns.logger.warn("[#{@app.name}] bad_request: #{current_registration_id} (#{response_body['reason']})")
            @failed_registration_ids[current_registration_id] = response_body['reason']
          end
        end

        def unauthorized(response)
          # Indicate a notification is retryable. Because ADM requires separate request for each push token, this will safely mark the entire notification to retry delivery.
          raise Rapns::RetryableError.new(response.code.to_i, @notification.id, 'ADM responded with an Unauthorized Error.', response)
        end

        def too_many_requests(response)
          # raise error so the current notification stops sending messages to remaining reg ids
          raise Rapns::TooManyRequestsError.new(response.code.to_i, @notification.id, 'Exceeded maximum allowable rate of messages.', response)
        end

        def internal_server_error(response, current_registration_id)
          @failed_registration_ids[current_registration_id] = "Internal Server Error"
          Rapns.logger.warn("[#{@app.name}] internal_server_error: #{current_registration_id} (Internal Server Error)")
        end

        def service_unavailable(response)
          # Indicate a notification is retryable. Because ADM requires separate request for each push token, this will safely mark the entire notification to retry delivery.
          raise Rapns::RetryableError.new(response.code.to_i, @notification.id, 'ADM responded with an Service Unavailable Error.', response)
        end

        def create_new_notification(response, registration_ids)
          attrs = @notification.attributes.slice('app_id', 'collapse_key', 'delay_while_idle')
          Rapns::Daemon.store.create_adm_notification(attrs, @notification.data, registration_ids, deliver_after_header(response), @notification.app)
        end

        def deliver_after_header(response)
          Rapns::Daemon::RetryHeaderParser.parse(response.header['retry-after'])
        end

        def retry_delivery(notification, response)
          if time = deliver_after_header(response)
            mark_retryable(notification, time)
          else
            mark_retryable_exponential(notification)
          end
        end

        def describe_errors
          if @failed_registration_ids.size == @notification.registration_ids.size
            "Failed to deliver to all recipients."
          else
            error_msgs = []
            @failed_registration_ids.each_pair { |regId, reason| error_msgs.push("#{regId}: #{reason}") }
            "Failed to deliver to recipients: \n#{error_msgs.join("\n")}"
          end
        end

        def retry_message
          "Notification #{@notification.id} will be retired after #{@notification.deliver_after.strftime("%Y-%m-%d %H:%M:%S")} (retry #{@notification.retries})."
        end

        def do_post(registration_id)
          adm_uri = URI.parse(AMAZON_ADM_URL % [registration_id])
          post = Net::HTTP::Post.new(adm_uri.path, initheader = {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'x-amzn-type-version' => 'com.amazon.device.messaging.ADMMessage@1.0',
            'x-amzn-accept-type' => 'com.amazon.device.messaging.ADMSendResult@1.0',
            'Authorization' => "Bearer #{get_access_token}"
          })
          post.body = @notification.as_json.to_json

          @http.request(adm_uri, post)
        end

        def get_access_token
          if(@notification.app.access_token.nil? || @notification.app.access_token_expired?)
            post = Net::HTTP::Post.new(AMAZON_TOKEN_URI.path, initheader = {'Content-Type' => 'application/x-www-form-urlencoded'})
            post.set_form_data(ACCESS_TOKEN_REQUEST_DATA.merge({'client_id' => @notification.app.client_id, 'client_secret' => @notification.app.client_secret}))

            handle_access_token(@http.request(AMAZON_TOKEN_URI, post))
          end

          @notification.app.access_token
        end

        def handle_access_token(response)
          if(response.code.to_i == 200)
            update_access_token(JSON.parse(response.body))
            Rapns::Daemon.store.update_app(@notification.app)
            Rapns.logger.info("ADM access token updated: token = #{@notification.app.access_token}, expires = #{@notification.app.access_token_expiration}")
          else
            Rapns.logger.warn("Could not retrieve access token from ADM: #{response.body}")
          end
        end

        def update_access_token(data)
          @notification.app.access_token = data['access_token']
          @notification.app.access_token_expiration = Time.now + data['expires_in'].to_i
        end
      end
    end
  end
end
