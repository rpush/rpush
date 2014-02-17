require 'spec_helper'

def is_unit_example?(example)
  path = example.metadata[:example_group][:file_path]
  path =~ /spec\/unit/
end

RSpec.configure do |config|
  # config.before :suite do
  #   PerfTools::CpuProfiler.start('/tmp/rpush_profile')
  # end
  # config.after :suite do
  #   PerfTools::CpuProfiler.stop
  # end

  config.before(:each) do
    if is_unit_example?(example)
      connection = ActiveRecord::Base.connection
      connection.increment_open_transactions
      connection.transaction_joinable = false
      connection.begin_db_transaction
    end
  end

  config.after(:each) do
    if is_unit_example?(example)
      connection = ActiveRecord::Base.connection
      if connection.open_transactions != 0
        connection.rollback_db_transaction
        connection.decrement_open_transactions
      end
    end
  end
end
