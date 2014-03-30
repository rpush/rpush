ENV['RAILS_ENV'] = 'test'

require 'bundler'
Bundler.require(:default)

require 'rpush'
require 'rpush/daemon'

Rpush.configure do |config|
  config.client = ENV['CLIENT'] || :active_record
end

case Rpush.config.client.to_sym
  when :active_record
    require 'support/active_record_setup'
end

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
  config.before(:each) do
    Rails.stub(root: '/tmp/rails_root')
  end

  config.after(:each) do
    after_example_cleanup
  end
end

