module Rapns
  class Feedback < ActiveRecord::Base
    set_table_name 'rapns_feedback'

    validates :device_token, :presence => true
    validates :failed_at, :presence => true

    validates_with Rapns::DeviceTokenFormatValidator
  end
end