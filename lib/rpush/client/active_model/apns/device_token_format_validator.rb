module Rpush
  module Client
    module ActiveModel
      module Apns
        class DeviceTokenFormatValidator < ::ActiveModel::Validator
          def validate(record)
            return if record.device_token =~ /^[a-z0-9]{64}$/i
            record.errors[:device_token] << "is invalid"
          end
        end
      end
    end
  end
end
