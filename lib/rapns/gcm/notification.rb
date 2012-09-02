module Rapns
  module Gcm
    class Notification < Rapns::Notification
      validates :registration_ids, :presence => true
      validates_with Rapns::Gcm::ExpiryCollapseKeyMutualInclusionValidator
    end
  end
end