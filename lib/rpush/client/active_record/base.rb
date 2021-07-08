module Rpush
  module Client
    module ActiveRecord
      class Base < ::ActiveRecord::Base
        self.abstract_class = true

        connects_to database: Rpush.config.database if ::ActiveRecord.version >= Gem::Version.new("6.0.0")
      end
    end
  end
end
