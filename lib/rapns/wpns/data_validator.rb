module Rapns
  module Wpns
    class DataValidator < ActiveModel::Validator
      def validate(record)
        if /https?:\/\/[\S]+/.match(record.uri) == nil
          record.errors[:uri] = "is invalid"
        end
        if record.alert == ""
          record.errors[:base] = "WP notification cannot have an empty body"
        end
      end
    end
  end
end
