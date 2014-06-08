module Rpush
  module Daemon
    class QueuePayload
      attr_reader :batch, :notification

      def initialize(batch: nil, notification: nil)
        @batch = batch
        @notification = notification
    end
  end
end
