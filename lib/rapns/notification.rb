module Rapns
  class Notification < ActiveRecord::Base
    self.table_name = 'rapns_notifications'

    attr_accessible *column_names.map(&:to_sym)

    validates :app, :presence => true

    scope :ready_for_delivery, lambda {
      where('delivered = ? AND failed = ? AND (deliver_after IS NULL OR deliver_after < ?)',
            false, false, Time.now)
    }
  end
end
