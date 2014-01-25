module Rpush
  class Notification < ActiveRecord::Base
    include Rpush::MultiJsonHelper

    self.table_name = 'rapns_notifications'

    # TODO: Dump using multi json.
    serialize :registration_ids

    belongs_to :app, :class_name => 'Rpush::App'

    if Rpush.attr_accessible_available?
      attr_accessible :badge, :device_token, :sound, :alert, :data, :expiry,:delivered,
        :delivered_at, :failed, :failed_at, :error_code, :error_description, :deliver_after,
        :alert_is_json, :app, :app_id, :collapse_key, :delay_while_idle, :registration_ids, :uri
    end

    validates :expiry, :numericality => true, :allow_nil => true
    validates :app, :presence => true

    scope :ready_for_delivery, lambda {
      where('delivered = ? AND failed = ? AND (deliver_after IS NULL OR deliver_after < ?)',
            false, false, Time.now)
    }

    scope :for_apps, lambda { |apps|
      where('app_id IN (?)', apps.map(&:id))
    }

    scope :completed, lambda { where("delivered = ? OR failed = ?", true, true) }

    def data=(attrs)
      return unless attrs
      raise ArgumentError, "must be a Hash" if !attrs.is_a?(Hash)
      write_attribute(:data, multi_json_dump(attrs.merge(data || {})))
    end

    def registration_ids=(ids)
      ids = [ids] if ids && !ids.is_a?(Array)
      super
    end

    def data
      multi_json_load(read_attribute(:data)) if read_attribute(:data)
    end

    def payload
      multi_json_dump(as_json)
    end

    def payload_size
      payload.bytesize
    end

    def payload_data_size
      multi_json_dump(as_json['data']).bytesize
    end

    class << self
      def created_before(dt)
        where("created_at < ?", dt)
      end

      def completed_and_older_than(dt)
        completed.created_before(dt)
      end
    end
  end
end
