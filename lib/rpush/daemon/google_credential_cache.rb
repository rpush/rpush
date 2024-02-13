require 'singleton'
module Rpush
  module Daemon
    class GoogleCredentialCache
      include Singleton
      include Loggable

      # Assuming tokens are valid for 1 hour
      TOKEN_VALID_FOR_SEC = 60 * 59

      def initialize
        @credentials_cache = {}
      end

      def access_token(scope, json_key)
        key = hash_key(scope, json_key)

        if @credentials_cache[key].nil? || Time.now > @credentials_cache[key][:expires_at]
          token = fetch_fresh_token(scope, json_key)
          expires_at = Time.now + TOKEN_VALID_FOR_SEC
          @credentials_cache[key] = { token: token, expires_at: expires_at }
        end

        @credentials_cache[key][:token]
      end

      private

      def fetch_fresh_token(scope, json_key)
        json_key_io = json_key ? StringIO.new(json_key) : nil
        log_debug("FCM - Obtaining access token.")
        authorizer = Google::Auth::ServiceAccountCredentials.make_creds(scope: scope, json_key_io: json_key_io)
        authorizer.fetch_access_token
      end

      def hash_key(scope, json_key)
        scope.hash ^ json_key.hash
      end
    end
  end
end
