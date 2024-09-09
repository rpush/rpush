# frozen_string_literal: true

module Rpush
  module Daemon
    class RetryHeaderParser
      def self.parse(header)
        new(header).parse
      end

      def initialize(header)
        @header = header
      end

      def parse
        return unless @header

        if /^[0-9]+$/.match?(@header.to_s)
          Time.zone.now + @header.to_i
        else
          Time.httpdate(@header)
        end
      end
    end
  end
end
