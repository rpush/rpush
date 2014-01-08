module Rapns
  module Adm
    class App < Rapns::App
      validates :client_id, :client_secret, :presence => true

      def access_token_expired?
        self.access_token_expiration.nil? || self.access_token_expiration < Time.now
      end
    end
  end
end