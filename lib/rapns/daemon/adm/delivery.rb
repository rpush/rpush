module Rapns
  module Daemon
    module Adm
      # https://developer.amazon.com/sdk/adm/sending-message.html
      class Delivery < Rapns::Daemon::Delivery
        include Rapns::MultiJsonHelper
        
        # Oauth2.0 token endpoint. This endpoint is used to request authorization tokens.
        AMAZON_TOKEN_URI = URI.parse('https://api.amazon.com/auth/O2/token')

        # ADM services endpoint. This endpoint is used to perform ADM requests.
        AMAZON_ADM_URL = 'https://api.amazon.com/messaging/registrations'

        # Data used to request authorization tokens.
        ACCESS_TOKEN_REQUEST_DATA = {"grant_type" => "client_credentials", "scope" => "messaging:push", "client_secret" => "", "client_id" => ""}

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
            
            if(@failed_registration_ids.empty?)
              mark_delivered
            else
              raise Rapns::DeliveryError.new(nil, @notification.id, describe_errors)
            end
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
          when 413
            request_entity_too_large(response)
          when 429
            too_many_requests(response)
          when 500
            internal_server_error(response)
          when 503
            service_unavailable(response)
          else
            raise Rapns::DeliveryError.new(response.code, @notification.id, HTTP_STATUS_CODES[response.code.to_i])
          end
        end

        def ok(response, current_registration_id)
          Rapns.logger.warn("handle_response: #{current_registration_id}, #{response.inspect}")
          response_body = multi_json_load(response.body)
          
          if(response_body.has_key?('registrationID'))
            @sent_registration_ids << response_body['registrationID']
            Rapns.logger.info("[#{@app.name}] #{@notification.id} sent to #{response_body['registrationID']}")
          end
          
          if(current_registration_id != response_body['registrationID'])
            reflect(:adm_canonical_id, current_registration_id, response_body['registrationID'])
          end
        end
        
        def handle_too_many_requests
          if(@sent_registration_ids.empty?)
            # none sent yet, just resend after the specified retry-after response.header
            retry_delivery(@notification, error.response)
          else
            # save unsent registration ids
            unsent_registration_ids = @notification.registration_ids.collect { |reg_id| !@sent_registration_ids.include?(reg_id) } 
                     
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
            Rapns.logger.warn("bad_request: #{current_registration_id} (#{response_body['reason']})")
            failed_registration_ids[current_registration_id] = response_body['reason']
          end
          # raise Rapns::DeliveryError.new(400, @notification.id, 'ADM failed to parse the JSON request. Possibly an rapns bug, please open an issue.')
        end
        
        def unauthorized(response)
          # clear app access_token so a new one is fetched
          @app.access_token = nil
          get_access_token
          
          mark_retryable(@notification, Time.zone.now)
        end
        
        def too_many_requests(response)
          # raise error so the current notification stops sending messages to remaining reg ids
          raise Rapns::TooManyRequestsError.new(429, @notification.id, 'Exceeded maximum allowable rate of messages.', response)
        end

        def internal_server_error(response)
          retry_delivery(@notification, response)
          Rapns.logger.warn("ADM responded with an Internal Error. " + retry_message)
        end

        def service_unavailable(response)
          retry_delivery(@notification, response)
          Rapns.logger.warn("ADM responded with an Service Unavailable Error. " + retry_message)
        end

        def create_new_notification(response, registration_ids)
          attrs = @notification.attributes.slice('app_id', 'collapse_key', 'delay_while_idle')
          Rapns::Daemon.store.create_adm_notification(attrs, @notification.data, registration_ids, deliver_after_header(response), @notification.app)
        end

        def deliver_after_header(response)
          if response.header['retry-after']
            if response.header['retry-after'].to_s =~ /^[0-9]+$/
              Time.now + response.header['retry-after'].to_i
            else
              Time.httpdate(response.header['retry-after'])
            end
          end
        end
        
        def retry_delivery(notification, response)
          if time = deliver_after_header(response)
            mark_retryable(notification, time)
          else
            mark_retryable_exponential(notification)
          end
        end

        def describe_errors
          description = if @failed_registration_ids.size == @notification.registration_ids.size
            "Failed to deliver to all recipients.}."
          else
            error_msgs = []
            @failed_registration_ids.each_pair { |regId, reason| error_msgs.push("#{regId}: #{reason}") }
            "Failed to deliver to recipients: \r\n#{error_msgs.join("\r\n")}"
          end
        end

        def retry_message
          "Notification #{@notification.id} will be retired after #{@notification.deliver_after.strftime("%Y-%m-%d %H:%M:%S")} (retry #{@notification.retries})."
        end

        def do_post(registration_id)
          adm_uri = URI.parse(AMAZON_ADM_URL + registration_id)
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
          if(@app.access_token.nil? || @app.access_token_expired?)
            ACCESS_TOKEN_REQUEST_DATA['client_id'] = @app.client_id
            ACCESS_TOKEN_REQUEST_DATA['client_secret'] = @app.client_secret
            
            post = Net::HTTP::Post.new(AMAZON_TOKEN_URI.path, initheader = {'Content-Type' => 'application/x-www-form-urlencoded'})
            post.set_form_data(ACCESS_TOKEN_REQUEST_DATA)
            
            response = @http.request(AMAZON_TOKEN_URI, post)
            
            if(response.code.to_i == 200)
              data = JSON.parse(response.body)
              @app.access_token = data['access_token']
              @app.access_token_expiration = Time.zone.now + data['expires_in'].to_i
              Rapns::Daemon.store.update_app(@app)
            else
              Rapns.logger.warn("Could not retrieve access token from ADM: #{response.body}")
            end
          end
          
          @app.access_token
        end

        HTTP_STATUS_CODES = {
          100  => 'Continue',
          101  => 'Switching Protocols',
          102  => 'Processing',
          200  => 'OK',
          201  => 'Created',
          202  => 'Accepted',
          203  => 'Non-Authoritative Information',
          204  => 'No Content',
          205  => 'Reset Content',
          206  => 'Partial Content',
          207  => 'Multi-Status',
          226  => 'IM Used',
          300  => 'Multiple Choices',
          301  => 'Moved Permanently',
          302  => 'Found',
          303  => 'See Other',
          304  => 'Not Modified',
          305  => 'Use Proxy',
          306  => 'Reserved',
          307  => 'Temporary Redirect',
          400  => 'Bad Request',
          401  => 'Unauthorized',
          402  => 'Payment Required',
          403  => 'Forbidden',
          404  => 'Not Found',
          405  => 'Method Not Allowed',
          406  => 'Not Acceptable',
          407  => 'Proxy Authentication Required',
          408  => 'Request Timeout',
          409  => 'Conflict',
          410  => 'Gone',
          411  => 'Length Required',
          412  => 'Precondition Failed',
          413  => 'Request Entity Too Large',
          414  => 'Request-URI Too Long',
          415  => 'Unsupported Media Type',
          416  => 'Requested Range Not Satisfiable',
          417  => 'Expectation Failed',
          418  => "I'm a Teapot",
          422  => 'Unprocessable Entity',
          423  => 'Locked',
          424  => 'Failed Dependency',
          426  => 'Upgrade Required',
          429  => 'Too Many Requests',
          500  => 'Internal Server Error',
          501  => 'Not Implemented',
          502  => 'Bad Gateway',
          503  => 'Service Unavailable',
          504  => 'Gateway Timeout',
          505  => 'HTTP Version Not Supported',
          506  => 'Variant Also Negotiates',
          507  => 'Insufficient Storage',
          510  => 'Not Extended',
        }
      end
    end
  end
end
