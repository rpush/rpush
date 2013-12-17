module Rapns
  module Wpns
    class DataValidator < ActiveModel::Validator
      def validate(record)
        if record.collapse_key.nil? && record.data.nil?
          # Don't know if this is needed.
          record.errors[:data] << "Must be set unless collapse_key is specified"
        end
      end
    end
  end
end
