module Rapns
  module Gcm
    class Notification < Rapns::Notification
      validates :auth_key, :presence => true
    end
  end
end