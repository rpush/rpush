module Modis
  module Transaction
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def transaction
        Redis.current.multi { yield }
      end
    end
  end
end
