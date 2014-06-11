module Rpush
  module Daemon
    module ServiceConfigMethods
      DISPATCHERS = {
        http: Rpush::Daemon::Dispatcher::Http,
        tcp: Rpush::Daemon::Dispatcher::Tcp,
        batched_tcp: Rpush::Daemon::Dispatcher::BatchedTcp
      }

      def batch_deliveries(value = nil)
        return batch_deliveries? if value.nil?
        @batch_deliveries = value
      end

      def batch_deliveries?
        @batch_deliveries == true
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
