require 'active_record'

jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

$adapter = ENV['ADAPTER'] || 'postgresql'
$adapter = 'jdbc' + $adapter if jruby

require 'yaml'
db_config = YAML.load_file(File.expand_path("config/database.yml", File.dirname(__FILE__)))

if db_config[$adapter].nil?
  puts "No such adapter '#{$adapter}'. Valid adapters are #{db_config.keys.join(', ')}."
  exit 1
end

if ENV['TRAVIS']
  db_config[$adapter]['username'] = 'postgres'
else
  require 'etc'
  username = $adapter =~ /mysql/ ? 'root' : Etc.getlogin
  db_config[$adapter]['username'] = username
end

puts "Using #{$adapter} adapter."

ActiveRecord::Base.configurations = { "test" => db_config[$adapter] }
ActiveRecord::Base.establish_connection(db_config[$adapter])

require 'generators/templates/add_rpush'

migrations = [AddRpush]

unless ENV['TRAVIS']
  migrations.reverse.each do |m|
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
