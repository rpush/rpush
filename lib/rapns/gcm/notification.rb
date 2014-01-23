module Rapns
  module Gcm
    class Notification < Rapns::Notification
      validates :registration_ids, :presence => true

      validates_with Rapns::PayloadDataSizeValidator, limit: 4096
      validates_with Rapns::RegistrationIdsCountValidator, limit: 1000

      validates_with Rapns::Gcm::ExpiryCollapseKeyMutualInclusionValidator

      def as_json
        json = {
          'registration_ids' => registration_ids,
          'delay_while_idle' => delay_while_idle,
          'data' => data
        }

        if collapse_key
          json['collapse_key'] = collapse_key
        end

        if expiry
          json['time_to_live'] = expiry
        end

        json
      end
    end
  end
end
