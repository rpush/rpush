require 'spec_helper'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

def functional_example?(example)
  path = example.metadata[:example_group][:file_path]
  path =~ /spec\/functional/
end

RSpec.configure do |config|
  config.before(:each) do
    SPEC_REDIS.keys('rpush:*').each { |key| SPEC_REDIS.del(key) }
  end

  config.after(:each) do
    DatabaseCleaner.clean if functional_example?(example)
  end
end
