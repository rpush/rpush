module Rapns
  class DeliveryError < StandardError
    attr_reader :code, :description

    def initialize(code, notification_id, description)
      @code = code
      @notification_id = notification_id
      @description = description
    end

    def message
      "Unable to deliver notification #{@notification_id}, received error #{@code} (#{@description})"
    end
  end
end