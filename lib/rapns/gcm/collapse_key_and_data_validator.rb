module Rapns
  module Gcm
    class CollapseKeyAndDataValidator < ActiveModel::Validator

      def validate(record)
        if record.collapse_key && record.data
          record.errors[:base] << "collapse_key and data cannot both be set."
        end
      end
    end
  end
end