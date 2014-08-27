require 'multi_json'
require 'active_support/all'

module Rpush
  def self.attr_accessible_available?
    require 'rails'
    ::Rails::VERSION::STRING < '4' || defined?(::ActiveRecord::MassAssignmentSecurity)
  end
end

require 'rpush/version'
require 'rpush/deprecation'
require 'rpush/deprecatable'
require 'rpush/logger'
require 'rpush/multi_json_helper'
require 'rpush/configuration'
require 'rpush/reflection'
require 'rpush/embed'
require 'rpush/push'
require 'rpush/apns_feedback'

module Rpush
  def self.jruby?
    defined? JRUBY_VERSION
  end

  def self.require_for_daemon
    require 'rpush/daemon'
  end

  def self.logger
    @logger ||= Logger.new
  end

  class << self
    attr_writer :logger
  end
end
