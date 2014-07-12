module Rpush
  module Client
    module ActiveModel
      module Apns
        class BinaryNotificationValidator < ::ActiveModel::Validator
          MAX_BYTES = 256

          def validate(record)
            return unless record.payload_size > MAX_BYTES
            record.errors[:base] << "APN notification cannot be larger than #{MAX_BYTES} bytes. Try condensing your alert and device attributes."
          end
        end
      end
    end
  end
end
