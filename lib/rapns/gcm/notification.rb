module Rapns
  module Gcm
    class Notification < Rapns::Notification
      validates :registration_ids, :presence => true
    end
  end
end