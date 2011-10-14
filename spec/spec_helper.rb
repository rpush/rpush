ENV['RAILS_ENV'] = 'test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'active_record'
adapters = ['mysql', 'mysql2', 'postgresql']
$adapter = ENV['ADAPTER'] || 'postgresql'

if !adapters.include?($adapter)
  puts "No such adapter '#{$adapter}'. Valid adapters are #{adapters.join(', ')}."
  exit 1
end

puts "Using #{$adapter} adapter."
ActiveRecord::Base.establish_connection('adapter' => $adapter, 'database' => 'rapns_test')
require 'generators/templates/create_rapns_notifications'

CreateRapnsNotifications.down rescue ActiveRecord::StatementInvalid
CreateRapnsNotifications.up

Bundler.require(:default)

require 'shoulda'
require 'database_cleaner'

DatabaseCleaner.strategy = :truncation

require 'rapns'
require 'rapns/daemon'

#require 'perftools'

RSpec.configure do |config|
  # config.before :suite do
  #   PerfTools::CpuProfiler.start('/tmp/rapns_profile')
  # end
  # config.after :suite do
  #   PerfTools::CpuProfiler.stop
  # end

  config.before(:each) { DatabaseCleaner.clean }
end
