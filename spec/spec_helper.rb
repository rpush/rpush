ENV['RAILS_ENV'] = 'test'

require 'bundler'
Bundler.require(:default)
client = (ENV['CLIENT'] || :active_record).to_sym

unless ENV['TRAVIS'] && ENV['QUALITY'] == 'false'
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

RAILS_ROOT = '/tmp/rails_root'

Rpush.configure do |config|
  config.client = client
  config.log_dir = RAILS_ROOT
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
end

RSpec.configure do |config|
  config.before(:each) do
    Rails.stub(root: RAILS_ROOT)
  end

  config.after(:each) do
    after_example_cleanup
  end
end
