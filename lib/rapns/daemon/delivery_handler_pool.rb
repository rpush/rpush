module Rapns
  module Daemon
    class DeliveryHandlerPool < Pool

      protected

      def new_object_for_pool(i)
        DeliveryHandler.new
      end

      def object_added_to_pool(object)
        object.start
      end

      def object_removed_from_pool(object)
        object.stop
      end

      def drain_started
        @num_objects.times { Rapns::Daemon.delivery_queue.push(Rapns::Daemon::DeliveryHandler::STOP) }
      end
    end
  end
end