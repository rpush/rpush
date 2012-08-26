module Rapns
  module Daemon
    module Gcm
      class DeliveryHandler
        include DatabaseReconnectable

        HOST = 'https://android.googleapis.com/gcm/send'
      end
    end
  end
end