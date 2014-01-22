module Rapns
  module Adm
    class Notification < Rapns::Notification
      validates :registration_ids, :presence => true

      validates_with Rapns::PayloadDataSizeValidator, limit: 6144

      validates_with Rapns::Adm::DataValidator
      validates_with Rapns::Adm::RegistrationIdsCountValidator

      def as_json
        json = {
          'data' => data
        }

        if collapse_key
          json['consolidationKey'] = collapse_key
        end

        # number of seconds before message is expired
        if expiry
          json['expiresAfter'] = expiry
        end

        json
      end
    end
  end
end
