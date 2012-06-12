module Rapns
  module Daemon
    class FeedbackReceiverPool
      def initialize
        @receivers = []
      end

      def <<(receiver)
        @receivers << receiver
        receiver.start
      end

      def drain
        @receivers.pop.stop while !@receivers.empty?
      end
    end
  end
end