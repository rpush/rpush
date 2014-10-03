require 'spec_helper'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

def functional_example?(example)
  path = example.metadata[:example_group][:file_path]
  path =~ /spec\/functional/
end

RSpec.configure do |config|
  config.before(:each) do
    Modis.with_connection do |redis|
      redis.keys('rpush:*').each { |key| redis.del(key) }
    end

    Rpush.config.logger = ::Logger.new(STDOUT) if functional_example?(example)
  end

  config.after(:each) do
    DatabaseCleaner.clean if functional_example?(example)
  end
end
