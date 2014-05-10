module Modis
  class ModisError < StandardError; end
  class RecordNotSaved < ModisError; end
  class RecordNotFound < ModisError; end
  class RecordInvalid < ModisError; end
  class UnsupportedAttributeType < ModisError; end
  class AttributeCoercionError < ModisError; end

  module Errors
    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end
  end
end
