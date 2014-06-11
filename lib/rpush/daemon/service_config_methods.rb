module Rpush
  module Daemon
    module ServiceConfigMethods
      DISPATCHERS = {
        http: Rpush::Daemon::Dispatcher::Http,
        tcp: Rpush::Daemon::Dispatcher::Tcp,
        bathed_tcp: Rpush::Daemon::Dispatcher::BatchedTcp
      }

      attr_writer :batch_deliveries

      def batch_deliveries?
        @batch_deliveries = true
      end

      def dispatcher(name = nil, options = {})
        @dispatcher_name = name
        @dispatcher_options = options
      end

      def dispatcher_class
        DISPATCHERS[@dispatcher_name] || (fail NotImplementedError)
      end

      def delivery_class
        const_get('Delivery')
      end

      def new_dispatcher(app)
        dispatcher_class.new(app, delivery_class, @dispatcher_options)
      end

      def loops(*loops)
        @loops ||= []
        @loops = loops if loops.any?
        @loops
      end
    end
  end
end
