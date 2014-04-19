require 'spec_helper'
require 'rails'

def is_unit_example?(example)
  path = example.metadata[:example_group][:file_path]
  path =~ /spec\/unit/
end

def rails4?
  ::Rails::VERSION::STRING >= '4'
end

redis = Redis.new

RSpec.configure do |config|
  # config.before :suite do
  #   PerfTools::CpuProfiler.start('/tmp/rpush_profile')
  # end
  # config.after :suite do
  #   PerfTools::CpuProfiler.stop
  # end

  config.before(:each) do
    Redis.new.keys('rpush:*').each { |key| redis.del(key) }

    if is_unit_example?(example)
      connection = ActiveRecord::Base.connection

      if rails4?
        connection.begin_transaction joinable: false
      else
        connection.increment_open_transactions
        connection.transaction_joinable = false
        connection.begin_db_transaction
      end
    end
  end

  config.after(:each) do
    if is_unit_example?(example)
      connection = ActiveRecord::Base.connection

      if rails4?
        connection.rollback_transaction if connection.transaction_open?
      else
        if connection.open_transactions != 0
          connection.rollback_db_transaction
          connection.decrement_open_transactions
        end
      end
    end
  end
end
