require 'spec_helper'
require 'rails'

def unit_example?(metadata)
  metadata[:file_path] =~ %r{spec/unit}
end

def rails4?
  ::Rails::VERSION::STRING >= '4'
end

RSpec.configure do |config|
  config.before(:each) do
    Modis.with_connection do |redis|
      redis.keys('rpush:*').each { |key| redis.del(key) }
    end if redis?

    if active_record? && unit_example?(self.class.metadata)
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
    if active_record? && unit_example?(self.class.metadata)
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
