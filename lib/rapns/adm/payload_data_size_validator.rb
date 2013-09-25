module Rapns
  module Adm
    class PayloadDataSizeValidator < ActiveModel::Validator
      LIMIT = 6144

      def validate(record)
        if !record.data.nil? && record.payload_data_size > LIMIT
          record.errors[:base] << "ADM notification payload data cannot be larger than #{LIMIT} bytes."
        end
      end
    end
  end
end
