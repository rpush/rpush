module Rpush
  module Client
    module ActiveRecord
      class Base < ::ActiveRecord::Base
        self.abstract_class = true

        connects_to database: Rpush.config.database
      end
    end
  end
end
