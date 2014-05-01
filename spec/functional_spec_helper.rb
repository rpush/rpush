require 'spec_helper'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

def is_functional_example?(example)
  path = example.metadata[:example_group][:file_path]
  path =~ /spec\/functional/
end

RSpec.configure do |config|
  config.before(:each) do
    SPEC_REDIS.keys('rpush:*').each { |key| SPEC_REDIS.del(key) }
  end

  config.after(:each) do
    if is_functional_example?(example)
      DatabaseCleaner.clean
    end
  end
end
