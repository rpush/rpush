require 'spec_helper'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

def functional_example?(metadata)
  metadata[:file_path] =~ %r{/spec/functional/}
end

def timeout(&blk)
  Timeout.timeout(10, &blk)
end

RSpec.configure do |config|
  config.before do
    if redis? && functional_example?(self.class.metadata)
      Modis.with_connection do |redis|
        redis.keys('rpush:*').each { |key| redis.del(key) }
      end
    end

    Rpush.config.logger = Logger.new(STDOUT) if functional_example?(self.class.metadata)
  end

  config.after do
    DatabaseCleaner.clean if active_record? && functional_example?(self.class.metadata)
  end
end
