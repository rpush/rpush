module Rpush
  module Client
    module Redis
      class Notification
        include Modis::Model

        self.namespace = 'notifications'
      end
    end
  end
end
