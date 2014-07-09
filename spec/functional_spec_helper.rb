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

    if functional_example?(example)
      Rails.stub(root: File.expand_path(File.join(File.dirname(__FILE__), '..', 'tmp')))
      Rpush.config.logger = ::Logger.new(STDOUT)
    end
  end

  config.after(:each) do
    DatabaseCleaner.clean if functional_example?(example)
  end
end
