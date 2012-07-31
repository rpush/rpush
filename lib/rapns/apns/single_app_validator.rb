module Rapns
  module Apns
    class SingleAppValidator < ActiveModel::Validator

      def validate(record)
        if record.app.size > 1
          record.errors[:app] << 'APNs does not support sending a notification to multiple apps.'
        end
      end
    end
  end
end