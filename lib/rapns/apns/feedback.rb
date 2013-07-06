module Rapns
  module Apns
    class Feedback < ActiveRecord::Base
      self.table_name = 'rapns_feedback'

      if Rapns.attr_accessible_available?
        attr_accessible :device_token, :failed_at, :app
      end

      validates :device_token, :presence => true
      validates :failed_at, :presence => true

      validates_with Rapns::Apns::DeviceTokenFormatValidator
    end
  end
end
