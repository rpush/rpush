module Rpush
  module Daemon
    module Reflectable
      def reflect(name, *args)
        Rpush.reflections.__dispatch(name, *args)
      rescue StandardError => e
        Rpush.logger.error(e)
      end
    end
  end
end
