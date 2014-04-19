module Rpush
  class CertificateExpiredError < StandardError
    attr_reader :app, :time

    def initialize(app, time)
      @app = app
      @time = time
    end

    def to_s
      message
    end

    def message
      "#{app.name} certificate expired at #{time}."
    end
  end
end

module Rpush
  class DisconnectionError < StandardError
    attr_accessor :message
    attr_reader :code, :description

    def initialize
      @code = nil
      @description = "Connection terminated without returning an error."
    end

    def to_s
      message
    end
  end
end
