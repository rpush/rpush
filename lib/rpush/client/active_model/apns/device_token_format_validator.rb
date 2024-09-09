# frozen_string_literal: true

module Rpush
  module Client
    module ActiveModel
      module Apns
        class DeviceTokenFormatValidator < ::ActiveModel::Validator
          def validate(record)
            return if /\A[a-z0-9]\w+\z/i.match?(record.device_token)

            record.errors.add :device_token, "is invalid"
          end
        end
      end
    end
  end
end
