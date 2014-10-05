module Rpush
  module Agent
    class Heartbeat
      def payload
        {
          id: Rpush::Agent.id,
          timestamp: Time.now.iso8601,
          version: Rpush::VERSION
        }
      end
    end
  end
end
