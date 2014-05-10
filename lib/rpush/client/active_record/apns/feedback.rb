module Rpush
  module Client
    module ActiveRecord
      module Apns
        class Feedback < ::ActiveRecord::Base
          self.table_name = 'rpush_feedback'

          if Rpush.attr_accessible_available?
            attr_accessible :device_token, :failed_at, :app
          end

          validates :device_token, presence: true
          validates :failed_at, presence: true

          validates_with Rpush::Client::ActiveModel::Apns::DeviceTokenFormatValidator
        end
      end
    end
  end
end
