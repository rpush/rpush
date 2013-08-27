ENV['RAILS_ENV'] = 'test'

begin
  require './spec/support/simplecov_helper'
  include SimpleCovHelper
  start_simple_cov("unit-#{RUBY_VERSION}")
rescue LoadError
  puts "Coverage disabled."
end

require 'active_record'
# require 'timecop'

jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

$adapter = ENV['ADAPTER'] || 'postgresql'
$adapter = 'jdbc' + $adapter if jruby

DATABASE_CONFIG = YAML.load_file(File.expand_path("../config/database.yml", File.dirname(__FILE__)))

if DATABASE_CONFIG[$adapter].nil?
  puts "No such adapter '#{$adapter}'. Valid adapters are #{DATABASE_CONFIG.keys.join(', ')}."
  exit 1
end

if ENV['TRAVIS']
  DATABASE_CONFIG[$adapter]['username'] = 'postgres'
else
  require 'etc'
  username = $adapter =~ /mysql/ ? 'root' : Etc.getlogin
  DATABASE_CONFIG[$adapter]['username'] = username
end

puts "Using #{$adapter} adapter."

ActiveRecord::Base.establish_connection(DATABASE_CONFIG[$adapter])

require 'generators/templates/create_rapns_notifications'
require 'generators/templates/create_rapns_feedback'
require 'generators/templates/add_alert_is_json_to_rapns_notifications'
require 'generators/templates/add_app_to_rapns'
require 'generators/templates/create_rapns_apps'
require 'generators/templates/add_gcm'

[CreateRapnsNotifications, CreateRapnsFeedback,
 AddAlertIsJsonToRapnsNotifications, AddAppToRapns, CreateRapnsApps, AddGcm].each do |migration|
  migration.down rescue ActiveRecord::StatementInvalid
  migration.up
end

require 'bundler'
Bundler.require(:default)

require 'database_cleaner'

# Ensure SQLite3Adapter is loaded before DatabaseCleaner so that DC
# can detect the correct superclass.
# SQLite3 is used by the acceptance tests.
require 'active_record/connection_adapters/sqlite3_adapter'

DatabaseCleaner.strategy = :truncation

require 'rapns'
require 'rapns/daemon'

Rapns::Notification.reset_column_information
Rapns::App.reset_column_information
Rapns::Apns::Feedback.reset_column_information

RSpec.configure do |config|
  # config.before :suite do
  #   PerfTools::CpuProfiler.start('/tmp/rapns_profile')
  # end
  # config.after :suite do
  #   PerfTools::CpuProfiler.stop
  # end

  config.before(:each) do
    DatabaseCleaner.clean
  end

  config.after(:each) do
    Rapns.logger = nil
    Rapns::Daemon.store = nil
    Rapns::Deprecation.muted do
      Rapns.config.set_defaults if Rapns.config.kind_of?(Rapns::Configuration)
    end
  end
end

# a test certificate that contains both an X509 certificate and
# a private key, similar to those used for connecting to Apple
# push notification servers.
#
# Note that we cannot validate the certificate and private key
# because we are missing the certificate chain used to validate
# the certificate, and this is private to Apple. So if the app
# has a certificate and a private key in it, the only way to find
# out if it really is valid is to connect to Apple's servers.

path = File.join(File.dirname(__FILE__), 'support')
TEST_CERT = File.read(File.join(path, 'cert_without_password.pem'))
TEST_CERT_WITH_PASSWORD = File.read(File.join(path, 'cert_with_password.pem'))
