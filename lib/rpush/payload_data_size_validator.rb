module Rpush
  class PayloadDataSizeValidator < ActiveModel::Validator
    def validate(record)
      limit = options[:limit] || 1024
      if !record.data.nil? && record.payload_data_size > limit
        record.errors[:base] << "Notification payload data cannot be larger than #{limit} bytes."
      end
    end
  end
end
