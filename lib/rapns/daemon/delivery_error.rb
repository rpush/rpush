module Rapns
  class DeliveryError < StandardError
    attr_reader :code, :description

    def initialize(code, description)
      @code = code
      @description = description
    end
  end
end