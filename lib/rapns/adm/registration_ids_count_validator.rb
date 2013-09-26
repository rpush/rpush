module Rapns
  module Adm
    class RegistrationIdsCountValidator < ActiveModel::Validator
      LIMIT = 100

      def validate(record)
        if record.registration_ids && record.registration_ids.size > LIMIT
          record.errors[:base] << "ADM notification number of registration_ids cannot be larger than #{LIMIT}."
        end
      end
    end
  end
end