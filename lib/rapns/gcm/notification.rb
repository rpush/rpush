module Rapns
  module Gcm
    class Notification < Rapns::Notification
      validates :auth_key, :presence => true

      validates_with Rapns::Gcm::CollapseKeyAndDataValidator
    end
  end
end