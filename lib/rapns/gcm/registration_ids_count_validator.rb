module Rapns
  module Gcm
    class RegistrationIdsCountValidator < ActiveModel::Validator
      LIMIT = 1000

      def validate(record)
        if record.registration_ids && record.registration_ids.size > LIMIT
          record.errors[:base] << "GCM notification number of registration_ids cannot be larger than #{LIMIT}."
        end
      end
    end
  end
end
