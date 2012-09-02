module Rapns
  module Gcm
    class PayloadSizeValidator < ActiveModel::Validator
      LIMIT = 4096

      def validate(record)
        if record.payload_size > LIMIT
          record.errors[:base] << "GCM notification payload cannot be larger than #{LIMIT} bytes."
        end
      end
    end
  end
end