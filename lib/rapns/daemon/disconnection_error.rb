module Rapns
  class DisconnectionError < StandardError
    attr_reader :code, :description

    def initialize
      @code = nil
      @description = "APNs disconnected without returning an error."
    end

    def message
      "The APNs disconnected without returning an error. This may indicate you are using an invalid certificate for the host."
    end
  end
end