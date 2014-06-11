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
    attr_reader :code, :message

    def initialize(message)
      @code = nil
      @message = message
    end

    def to_s
      message
    end
  end
end
