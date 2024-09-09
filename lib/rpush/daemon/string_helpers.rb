module Rpush
  module Daemon
    module StringHelpers
      def pluralize(count, singular, plural = nil)
        word = if count == 1
                 singular
               else
                 plural || singular.pluralize
               end

        "#{count || 0} #{word}"
      end
    end
  end
end
