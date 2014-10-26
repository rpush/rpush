ENV['RAILS_ENV'] = 'test'
client = (ENV['CLIENT'] || :active_record).to_sym

require 'bundler/setup'
Bundler.require(:default)

if !ENV['TRAVIS'] || (ENV['TRAVIS'] && ENV['QUALITY'] == 'true')
  begin
    require './spec/support/simplecov_helper'
    include SimpleCovHelper
    start_simple_cov("rpush-#{client}-#{RUBY_VERSION}")
  rescue LoadError
    puts "Coverage disabled."
  end
end

require 'rpush'
require 'rpush/daemon'
require 'rpush/client/redis'
require 'rpush/client/active_record'
require 'rpush/daemon/store/active_record'
require 'rpush/daemon/store/redis'

require 'support/active_record_setup'

RPUSH_ROOT = '/tmp/rails_root'

Rpush.configure do |config|
  config.client = client
end

RPUSH_CLIENT = Rpush.config.client

def active_record?
  Rpush.config.client == :active_record
end

path = File.join(File.dirname(__FILE__), 'support')
TEST_CERT = File.read(File.join(path, 'cert_without_password.pem'))
TEST_CERT_WITH_PASSWORD = File.read(File.join(path, 'cert_with_password.pem'))

def after_example_cleanup
  Rpush.logger = nil
  Rpush::Daemon.store = nil
  Rpush::Deprecation.muted do
    Rpush.config.set_defaults if Rpush.config.is_a?(Rpush::Configuration)
    Rpush.config.client = RPUSH_CLIENT
  end
  Rpush.plugins.values.each(&:unload)
  Rpush.instance_variable_set('@plugins', {})
end

RSpec.configure do |config|
  config.before(:each) do
    Rpush.config.log_file = File.join(RPUSH_ROOT, 'rpush.log')
    Rpush.stub(root: RPUSH_ROOT)
  end

  config.after(:each) do
    after_example_cleanup
  end
end
