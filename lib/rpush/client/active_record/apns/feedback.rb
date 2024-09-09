# frozen_string_literal: true

module Rpush
  module Client
    module ActiveRecord
      module Apns
        class Feedback < ApplicationRecord
          self.table_name = 'rpush_feedback'

          belongs_to :app, class_name: 'Rpush::Client::ActiveRecord::App'

          validates :device_token, presence: true
          validates :failed_at, presence: true

          validates_with Rpush::Client::ActiveModel::Apns::DeviceTokenFormatValidator
        end
      end
    end
  end
end
