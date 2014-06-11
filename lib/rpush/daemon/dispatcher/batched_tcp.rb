module Rpush
  module Daemon
    module Dispatcher
      class BatchedTcp < Rpush::Daemon::Dispatcher::Tcp
        def dispatch(payload)
          @delivery_class.new(@app, payload.batch).perform
        end
      end
    end
  end
end
