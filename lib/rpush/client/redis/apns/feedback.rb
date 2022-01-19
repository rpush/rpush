module Rpush
  module Client
    module Redis
      module Apns
        class Feedback
          include Modis::Model

          enable_all_index false # prevent creation of rpush:rpush:client:redis:apns:feedback:all set

          attribute :app_id, :integer
          attribute :device_token, :string
          attribute :failed_at, :timestamp

          validates :device_token, presence: true
          validates :failed_at, presence: true

          validates_with Rpush::Client::ActiveModel::Apns::DeviceTokenFormatValidator
        end
      end
    end
  end
end
