module Rapns
  module Gcm
    class App < Rapns::App
      validates :auth_key, :presence => true

      def service_name
        'gcm'
      end
    end
  end
end
