module Rapns
  module Deprecatable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def deprecated(method_name, version, msg=nil)
        Rapns::Deprecation.new(self, method_name, version, msg)
      end
    end
  end
end
