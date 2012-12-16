module Rapns
  module Deprecatable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def deprecated(method_name, version, msg=nil)
        instance_eval do
          alias_method "#{method_name}_without_warning", method_name
        end
        warning = "#{method_name} is deprecated and will be removed from Rapns #{version}."
        warning << " #{msg}" if msg
        class_eval(<<-RUBY, __FILE__, __LINE__)
          def #{method_name}(*args, &blk)
            Rapns::Deprecation.warn(#{warning.inspect})
            #{method_name}_without_warning(*args, &blk)
          end
        RUBY
      end
    end
  end
end
