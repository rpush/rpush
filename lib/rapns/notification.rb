module Rapns
  class Notification < ActiveRecord::Base
    self.table_name = 'rapns_notifications'

    serialize :registration_ids

    belongs_to :app, :class_name => 'Rapns::App'

    attr_accessible :badge, :device_token, :sound, :alert, :data, :expiry,:delivered,
      :delivered_at, :failed, :failed_at, :error_code, :error_description, :deliver_after,
      :alert_is_json, :app, :app_id, :collapse_key, :delay_while_idle, :registration_ids

    validates :expiry, :numericality => true, :allow_nil => true
    validates :app, :presence => true

    scope :ready_for_delivery, lambda {
      where('delivered = ? AND failed = ? AND (deliver_after IS NULL OR deliver_after < ?)',
            false, false, Time.now)
    }

    def initialize(attributes = nil, options = {})
      if attributes.is_a?(Hash) && attributes.keys.include?(:attributes_for_device)
        msg = ":attributes_for_device via mass-assignment is deprecated. Use :data or the attributes_for_device= instance method."
        ActiveSupport::Deprecation.warn(msg, caller(1))
      end
      super
    end

    def data=(attrs)
      raise ArgumentError, "must be a Hash" if !attrs.is_a?(Hash)
      write_attribute(:data, multi_json_dump(attrs))
    end

    def data
      multi_json_load(read_attribute(:data)) if read_attribute(:data)
    end

    protected

    def multi_json_load(string, options = {})
      # Calling load on multi_json less than v1.3.0 attempts to load a file from disk.
      if Gem.loaded_specs['multi_json'].version >= Gem::Version.create('1.3.0')
        MultiJson.load(string, options)
      else
        MultiJson.decode(string, options)
      end
    end

    def multi_json_dump(string, options = {})
      MultiJson.respond_to?(:dump) ? MultiJson.dump(string, options) : MultiJson.encode(string, options)
    end
  end
end
