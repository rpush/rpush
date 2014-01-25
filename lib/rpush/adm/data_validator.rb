module Rpush
  module Adm
    class DataValidator < ActiveModel::Validator
      def validate(record)
        if record.collapse_key.nil? && record.data.nil?
          record.errors[:data] << "must be set unless collapse_key is specified"
        end
      end
    end
  end
end
