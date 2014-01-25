module Rpush
  module Daemon
    module Reflectable
      def reflect(name, *args)
        begin
          Rpush.reflections.__dispatch(name, *args)
        rescue StandardError => e
          Rpush.logger.error(e)
        end
      end
    end
  end
end
