require 'active_record'

jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

SPEC_ADAPTER = ENV['ADAPTER'] || 'postgresql'
SPEC_ADAPTER = 'jdbc' + SPEC_ADAPTER if jruby

require 'yaml'
db_config = YAML.load_file(File.expand_path("config/database.yml", File.dirname(__FILE__)))

if db_config[SPEC_ADAPTER].nil?
  puts "No such adapter '#{SPEC_ADAPTER}'. Valid adapters are #{db_config.keys.join(', ')}."
  exit 1
end

if ENV['TRAVIS']
  db_config[SPEC_ADAPTER]['username'] = 'postgres'
else
  require 'etc'
  username = SPEC_ADAPTER =~ /mysql/ ? 'root' : Etc.getlogin
  db_config[SPEC_ADAPTER]['username'] = username
end

puts "Using #{SPEC_ADAPTER} adapter."

ActiveRecord::Base.configurations = { "test" => db_config[SPEC_ADAPTER] }
ActiveRecord::Base.establish_connection(db_config[SPEC_ADAPTER])

require 'generators/templates/add_rpush'
require 'generators/templates/rpush_2_0_0_updates'
require 'generators/templates/rpush_2_1_0_updates'
require 'generators/templates/rpush_2_6_0_updates'
require 'generators/templates/rpush_2_7_0_updates'
require 'generators/templates/rpush_3_0_0_updates'

migrations = [AddRpush, Rpush200Updates, Rpush210Updates, Rpush260Updates, Rpush270Updates, Rpush300Updates]

unless ENV['TRAVIS']
  migrations.reverse_each do |m|
    begin
      m.down
    rescue ActiveRecord::StatementInvalid => e
      p e
    end
  end
end

migrations.each(&:up)

Rpush::Client::ActiveRecord::Notification.reset_column_information
Rpush::Client::ActiveRecord::App.reset_column_information
Rpush::Client::ActiveRecord::Apns::Feedback.reset_column_information
