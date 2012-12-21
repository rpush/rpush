require 'active_record'
require 'multi_json'

require 'rapns/version'
require 'rapns/deprecation'
require 'rapns/deprecatable'
require 'rapns/multi_json_helper'
require 'rapns/notification'
require 'rapns/app'
require 'rapns/configuration'
require 'rapns/embed'
require 'rapns/push'

require 'rapns/apns/binary_notification_validator'
require 'rapns/apns/device_token_format_validator'
require 'rapns/apns/required_fields_validator'
require 'rapns/apns/notification'
require 'rapns/apns/feedback'
require 'rapns/apns/app'

require 'rapns/gcm/expiry_collapse_key_mutual_inclusion_validator'
require 'rapns/gcm/payload_size_validator'
require 'rapns/gcm/notification'
require 'rapns/gcm/app'

module Rapns
  def self.require_for_daemon
    require 'rapns/daemon'
    require 'rapns/patches'
  end
end
