ENV['RAILS_ENV'] = 'test'

require 'bundler'
Bundler.require(:default)

require 'active_record'

unless ENV['TRAVIS'] && ENV['QUALITY'] == 'false'
  begin
    require './spec/support/simplecov_helper'
    include SimpleCovHelper
    start_simple_cov("unit-#{RUBY_VERSION}")
  rescue LoadError
    puts "Coverage disabled."
  end
end

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
require 'generators/templates/add_wpns'
require 'generators/templates/add_adm'
require 'generators/templates/rename_rapns_to_rpush'

migrations = [CreateRapnsNotifications, CreateRapnsFeedback,
 AddAlertIsJsonToRapnsNotifications, AddAppToRapns, CreateRapnsApps, AddGcm,
 AddWpns, AddAdm, RenameRapnsToRpush]

migrations.reverse.each do |m|
  begin
    m.down
  rescue ActiveRecord::StatementInvalid => e
    p e
  end
end

migrations.each(&:up)

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

require 'rpush'
require 'rpush/daemon'

Rpush::Notification.reset_column_information
Rpush::App.reset_column_information
Rpush::Apns::Feedback.reset_column_information

RSpec.configure do |config|
  # config.before :suite do
  #   PerfTools::CpuProfiler.start('/tmp/rpush_profile')
  # end
  # config.after :suite do
  #   PerfTools::CpuProfiler.stop
  # end

  config.before(:each) do
    DatabaseCleaner.clean
  end

  config.after(:each) do
    Rpush.logger = nil
    Rpush::Daemon.store = nil
    Rpush::Deprecation.muted do
      Rpush.config.set_defaults if Rpush.config.kind_of?(Rpush::Configuration)
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
