module Rpush
  module Client
    module Mongoid
      module Apns
        class Feedback
          include ::Mongoid::Document

          field :device_token, type: String
          field :failed_at, type: Time

          belongs_to :app

          validates :device_token, presence: true
          validates :failed_at, presence: true

          index device_token: 1
          index app_id: 1

          validates_with Rpush::Client::ActiveModel::Apns::DeviceTokenFormatValidator
        end
      end
    end
  end
end
