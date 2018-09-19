module ActiveModel
  module Dirty
    private

    def attribute_will_change!(attr)
      return if attribute_changed?(attr)

      begin
        value = __send__(attr)
        value = value.duplicable? ? value.clone : value
      rescue TypeError, NoMethodError
      end

      set_attribute_was(attr, value)
    end

    def attribute_changed?(attr, from: OPTION_NOT_GIVEN, to: OPTION_NOT_GIVEN) # :nodoc:
      !!changes_include?(attr) &&
        (to == OPTION_NOT_GIVEN || to == __send__(attr)) &&
        (from == OPTION_NOT_GIVEN || from == changed_attributes[attr])
    end

    #Returns +true+ if attr_name is changed, +false+ otherwise.
    def changes_include?(attr_name)
      attributes_changed_by_setter.include?(attr_name)
    end
  end

  module Validations
    class NumericalityValidator < EachValidator
      def record_attribute_changed_in_place?(record, attr_name)
        false
      end
    end
  end
end
