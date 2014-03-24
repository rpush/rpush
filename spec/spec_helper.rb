ENV['RAILS_ENV'] = 'test'

require 'bundler'
Bundler.require(:default)

require 'active_record'

unless ENV['TRAVIS']
  unless ENV['TRAVIS'] && ENV['QUALITY'] == 'false'
    begin
      require './spec/support/simplecov_helper'
      include SimpleCovHelper
      start_simple_cov("unit-#{RUBY_VERSION}")
    rescue LoadError
      puts "Coverage disabled."
    end
  end
end

jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

$adapter = ENV['ADAPTER'] || 'postgresql'
$adapter = 'jdbc' + $adapter if jruby

require 'yaml'
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

ActiveRecord::Base.configurations = {"test" => DATABASE_CONFIG[$adapter]}
ActiveRecord::Base.establish_connection(DATABASE_CONFIG[$adapter])

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

require 'rpush'
require 'rpush/daemon'

# TEMPORARY
require 'rpush/client/active_record'

module Rpush
  include Rpush::Client::ActiveRecord

  module Apns
    include Rpush::Client::ActiveRecord::Apns
  end

  module Gcm
    include Rpush::Client::ActiveRecord::Gcm
  end

  module Wpns
    include Rpush::Client::ActiveRecord::Wpns
  end

  module Adm
    include Rpush::Client::ActiveRecord::Adm
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

def after_example_cleanup
  Rpush.logger = nil
  Rpush::Daemon.store = nil
  Rpush::Deprecation.muted do
    Rpush.config.set_defaults if Rpush.config.kind_of?(Rpush::Configuration)
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    Rpush::Client::ActiveRecord::Notification.reset_column_information
    Rpush::Client::ActiveRecord::App.reset_column_information
    Rpush::Client::ActiveRecord::Apns::Feedback.reset_column_information
  end

  config.before(:each) do
    Rails.stub(root: '/tmp/rails_root')
  end

  config.after(:each) do
    after_example_cleanup
  end
end

