module Rapns
  module Daemon
    module Gcm
      # http://developer.android.com/guide/google/gcm/gcm.html#response
      class Delivery < Rapns::Daemon::Delivery
        include Rapns::MultiJsonHelper

        GCM_URI = URI.parse('https://android.googleapis.com/gcm/send')
        UNAVAILABLE_STATES = ['Unavailable', 'InternalServerError']
        INVALID_REGISTRATION_ID_STATES = ['InvalidRegistration', 'MismatchSenderId', 'NotRegistered', 'InvalidPackageName']

        def initialize(app, http, notification, batch)
          @app = app
          @http = http
          @notification = notification
          @batch = batch
        end

        def perform
          begin
            handle_response(do_post)
          rescue Rapns::DeliveryError => error
            mark_failed(error.code, error.description)
            raise
          end
        end

        protected

        def handle_response(response)
          case response.code.to_i
          when 200
            ok(response)
          when 400
            bad_request
          when 401
            unauthorized
          when 500
            internal_server_error(response)
          when 503
            service_unavailable(response)
          else
            raise Rapns::DeliveryError.new(response.code, @notification.id, HTTP_STATUS_CODES[response.code.to_i])
          end
        end

        def ok(response)
          body = multi_json_load(response.body)

          failures = {
            invalid: [],
            unavailable: [],
            all: []
          }

          body['results'].zip(@notification.registration_ids).each_with_index do |(result, registration_id), index|
            if result['message_id']
              handle_success(registration_id, result['registration_id'])
            elsif error = result['error']
              case error
              when *INVALID_REGISTRATION_ID_STATES
                failures[:invalid] << [index, error]
              when *UNAVAILABLE_STATES
                failures[:unavailable] << [index, error]
              end
              failures[:all] << [index, error]
            end
          end

          if failures[:unavailable].count == @notification.registration_ids.count
            Rapns.logger.warn("All recipients unavailable. #{retry_message}")
            retry_delivery(@notification, response)
          elsif failures[:all].count > 0
            handle_failures(failures, response)
          else
            mark_delivered
            Rapns.logger.info("[#{@app.name}] #{@notification.id} sent to #{@notification.registration_ids.join(', ')}")
          end
        end

        def handle_success(registration_id, canonical_id)
          reflect(:gcm_delivered_to_recipient, @notification, registration_id)
          reflect(:gcm_canonical_id, registration_id, canonical_id) unless canonical_id.nil?
        end

        def handle_failures(failures, response)
          failures[:invalid].each do |index, error|
            registration_id = @notification.registration_ids[index]
            reflect(:gcm_invalid_registration_id, @app, error, registration_id)
          end

          if failures[:all].count == @notification.registration_ids.size
            error_description = "Failed to deliver to all recipients."
          else
            index_list = failures[:all].map(&:first)
            error_description = "Failed to deliver to recipients #{index_list.join(', ')}."
          end

          error_list = failures[:all].map(&:last)
          error_description += " Errors: #{error_list.join(', ')}."

          if failures[:unavailable].count > 0
            unavailable_idxs = failures[:unavailable].map(&:first)
            new_notification = create_new_notification(response, unavailable_idxs)
            error_description += " #{unavailable_idxs.join(', ')} will be retried as notification #{new_notification.id}."
          end

          raise Rapns::DeliveryError.new(nil, @notification.id, error_description)
        end

        def create_new_notification(response, unavailable_idxs)
          attrs = @notification.attributes.slice('app_id', 'collapse_key', 'delay_while_idle')
          registration_ids = @notification.registration_ids.values_at(*unavailable_idxs)
          Rapns::Daemon.store.create_gcm_notification(attrs, @notification.data,
            registration_ids, deliver_after_header(response), @notification.app)
        end

        def bad_request
          raise Rapns::DeliveryError.new(400, @notification.id, 'GCM failed to parse the JSON request. Possibly an rapns bug, please open an issue.')
        end

        def unauthorized
          raise Rapns::DeliveryError.new(401, @notification.id, 'Unauthorized, check your App auth_key.')
        end

        def internal_server_error(response)
          retry_delivery(@notification, response)
          Rapns.logger.warn("GCM responded with an Internal Error. " + retry_message)
        end

        def service_unavailable(response)
          retry_delivery(@notification, response)
          Rapns.logger.warn("GCM responded with an Service Unavailable Error. " + retry_message)
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

        def retry_message
          "Notification #{@notification.id} will be retried after #{@notification.deliver_after.strftime("%Y-%m-%d %H:%M:%S")} (retry #{@notification.retries})."
        end

        def do_post
          post = Net::HTTP::Post.new(GCM_URI.path, initheader = {'Content-Type'  => 'application/json',
                                                                 'Authorization' => "key=#{@notification.app.auth_key}"})
          post.body = @notification.as_json.to_json
          @http.request(GCM_URI, post)
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
