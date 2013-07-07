require 'active_record'
require 'multi_json'

module Rapns
  def self.attr_accessible_available?
    require 'rails'
    ::Rails::VERSION::STRING < '4'
  end
end

require 'rapns/version'
require 'rapns/deprecation'
require 'rapns/deprecatable'
require 'rapns/logger'
require 'rapns/multi_json_helper'
require 'rapns/notification'
require 'rapns/app'
require 'rapns/configuration'
require 'rapns/reflection'
require 'rapns/embed'
require 'rapns/push'
require 'rapns/apns_feedback'
require 'rapns/upgraded'

require 'rapns/apns/binary_notification_validator'
require 'rapns/apns/device_token_format_validator'
require 'rapns/apns/notification'
require 'rapns/apns/feedback'
require 'rapns/apns/app'

require 'rapns/gcm/expiry_collapse_key_mutual_inclusion_validator'
require 'rapns/gcm/payload_data_size_validator'
require 'rapns/gcm/registration_ids_count_validator'
require 'rapns/gcm/notification'
require 'rapns/gcm/app'

module Rapns
  def self.jruby?
    defined? JRUBY_VERSION
  end

  def self.require_for_daemon
    require 'rapns/daemon'
    require 'rapns/patches'
  end

  def self.logger
    @logger ||= Logger.new(:foreground => Rapns.config.foreground,
                           :airbrake_notify => Rapns.config.airbrake_notify)
  end

  def self.logger=(logger)
    @logger = logger
  end
end
