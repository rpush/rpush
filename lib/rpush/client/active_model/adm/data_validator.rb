module Rpush
  module Client
    module ActiveModel
      module Adm
        class DataValidator < ::ActiveModel::Validator
          def validate(record)
            return unless record.collapse_key.nil? && record.data.nil?
            record.errors[:data] << 'must be set unless collapse_key is specified'
          end
        end
      end
    end
  end
end
