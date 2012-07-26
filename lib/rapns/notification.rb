module Rapns
  class Notification < ActiveRecord::Base
    self.table_name = 'rapns_notifications'

    attr_accessible :badge, :device_token, :sound, :alert, :attributes_for_device, :expiry,:delivered,
      :delivered_at, :failed, :failed_at, :error_code, :error_description, :deliver_after, :alert_is_json, :app

    validates :app, :presence => true

    scope :ready_for_delivery, lambda {
      where('delivered = ? AND failed = ? AND (deliver_after IS NULL OR deliver_after < ?)',
            false, false, Time.now)
    }
  end
end
