module Rpush
  module Daemon
    module Hms
      class Token
        ONE_HOUR = 3600
        TOKEN_TTL = ONE_HOUR * 0.9
        AUD = "https://oauth-login.cloud.huawei.com/oauth2/v3/token".freeze
        # @param [Rpush::Client::Redis::App, Rpush::Client::ActiveRecord::App] app
        def initialize(app)
          @app = app
        end

        def token
          if @cached_token && !expired_token?
            @cached_token
          else
            new_token
          end
        end

        private

        def new_token
          @cached_token_at = Time.now
          now = Time.now.utc.to_i
          rs_key = OpenSSL::PKey::RSA.new(@app.hms_key)
          @cached_token = JWT.encode(
            {
              iss: @app.hms_sub_acc_id,
              iat: now,
              aud: AUD,
              exp: now + ONE_HOUR
            },
            rs_key,
            'RS256',
            {
              alg: 'RS256',
              typ: 'JWT',
              kid: @app.hms_key_id
            }
          )
        end

        def expired_token?
          Time.now - @cached_token_at >= TOKEN_TTL
        end
      end
    end
  end
end
