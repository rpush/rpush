require 'spec_helper'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

def functional_example?(metadata)
  metadata[:file_path] =~ /spec\/functional/
end

RSpec.configure do |config|
  config.before(:each) do
    Modis.with_connection do |redis|
      redis.keys('rpush:*').each { |key| redis.del(key) }
    end if redis?

    Rpush.config.logger = ::Logger.new(STDOUT) if functional_example?(self.class.metadata)
  end

  config.after(:each) do
    DatabaseCleaner.clean if active_record? && functional_example?(self.class.metadata)
  end
end
