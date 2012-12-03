ENV['RAILS_ENV'] = 'test'

begin
  require './spec/support/simplecov_helper'
  include SimpleCovHelper
  start_simple_cov('unit')
rescue LoadError
  puts "Coverage disabled."
end

require 'active_record'

jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

$adapter = ENV['ADAPTER'] ||
  if jruby
    'jdbcpostgresql'
  else
    'postgresql'
  end

DATABASE_CONFIG = YAML.load_file(File.expand_path("../config/database.yml", File.dirname(__FILE__)))

if DATABASE_CONFIG[$adapter].nil?
  puts "No such adapter '#{$adapter}'. Valid adapters are #{DATABASE_CONFIG.keys.join(', ')}."
  exit 1
end

if ENV['TRAVIS']
  DATABASE_CONFIG[$adapter]['username'] = 'postgres'
else
  require 'etc'
  DATABASE_CONFIG[$adapter]['username'] = Etc.getlogin
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

require 'shoulda'
require 'database_cleaner'

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

  config.before(:each) { DatabaseCleaner.clean }
end
