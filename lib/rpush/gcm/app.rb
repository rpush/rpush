module Rpush
  module Gcm
    class App < Rpush::App
      validates :auth_key, :presence => true

      def service_name
        'gcm'
      end
    end
  end
end
