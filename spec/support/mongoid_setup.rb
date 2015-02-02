require 'mongoid'

mongoid_yml = File.expand_path("config/mongoid.yml", File.dirname(__FILE__))
Mongoid.load!(mongoid_yml)

RSpec.configure do |config|
  config.before(:each) do
    Mongoid.purge!
  end
end
