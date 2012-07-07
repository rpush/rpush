module Rapns
  module Daemon
  	class DeliveryQueue19
      def initialize
        @mutex = Mutex.new
      end

      def push(notification)
        @mutex.synchronize do
          @num_notifications += 1
          @queue.push(notification)

          begin
            t = @waiting.shift
            t.wakeup if t
          rescue ThreadError
            retry
          end
        end
      end

      def pop
        @mutex.synchronize do
          while true
            if @queue.empty?
              @waiting.push Thread.current
              @mutex.sleep
            else
              return @queue.shift
            end
          end
        end
      end

      protected

      def synchronize(&blk)
      	@mutex.synchronize(&blk)
      end

      def mutext
        @mutex
      end
  	end
  end
end