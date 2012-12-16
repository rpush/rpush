module Rapns
  module Deprecatable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def deprecated(method_name, msg)
      end
    end

    def deprecated(method_name, msg)
    end
  end
end
