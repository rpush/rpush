module Rpush
  module Daemon
    class SignalHandler
      class << self
        attr_reader :thread
      end

      def self.start
        return unless trap_signals?
        @shutting_down = false
        read_io, @write_io = IO.pipe
        start_handler(read_io)
        %w(INT TERM HUP USR2).each do |signal|
          Signal.trap(signal) { @write_io.write("#{Signal.list[signal]}\n") }
        end
      end

      def self.stop
        @write_io.write("shutdown\n") if @write_io
        @thread.join if @thread
      end

      def self.start_handler(read_io)
        @thread = Thread.new do
          loop do
            case read_io.readline.strip.to_i
            when Signal.list['HUP']
              Synchronizer.sync
              Feeder.wakeup
            when Signal.list['USR2']
              AppRunner.debug
            when Signal.list['INT'], Signal.list['TERM']
              Thread.new { handle_shutdown_signal }
            else
              break
            end
          end
        end
      end

      def self.handle_shutdown_signal
        @shutting_down = true
        Rpush::Daemon.shutdown
      end

      def self.trap_signals?
        !Rpush.config.embedded
      end
    end
  end
end
