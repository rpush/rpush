module Rapns
  module Adm
    class Notification < Rapns::Notification
      validates :registration_ids, :presence => true
      validates_with Rapns::Adm::DataValidator
      validates_with Rapns::Adm::PayloadDataSizeValidator
      validates_with Rapns::Adm::RegistrationIdsCountValidator

      def registration_ids=(ids)
        ids = [ids] if ids && !ids.is_a?(Array)
        super
      end

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

      def payload_data_size
        multi_json_dump(as_json['data']).bytesize
      end
    end
  end
end
