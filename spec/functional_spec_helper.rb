require 'spec_helper'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

def is_functional_example?(example)
  path = example.metadata[:example_group][:file_path]
  path =~ /spec\/functional/
end

redis = Redis.new

RSpec.configure do |config|
  config.after(:each) do
    if is_functional_example?(example)
      DatabaseCleaner.clean
      Redis.new.keys('rpush:*').each { |key| redis.del(key) }
    end
  end
end
