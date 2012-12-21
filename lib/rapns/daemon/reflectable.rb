module Rapns
  module Daemon
    module Reflectable
      def reflect(name, *args)
        begin
          Rapns.reflections.__dispatch(name, *args)
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        end
      end
    end
  end
end
