module Rapns
  class DeliveryError < StandardError
    attr_reader :code, :description, :notification_id

    def initialize(code, description, notification_id)
      @code = code
      @description = description
      @notification_id = notification_id
    end

    def message
      "Unable to deliver notification #{notification_id}, received APN error #{code} (#{description})"
    end
  end
end