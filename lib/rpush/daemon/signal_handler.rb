module Rpush
  module Daemon
    class SignalHandler
      class << self
        attr_reader :thread
      end

      def self.start
        return unless trap_signals?

        read_io, @write_io = IO.pipe
        start_handler(read_io)
        %w(INT TERM HUP USR2).each do |signal|
          Signal.trap(signal) { @write_io.puts(signal) }
        end
      end

      def self.stop
        @write_io.puts('break') if @write_io
        @thread.join if @thread
      end

      def self.start_handler(read_io)
        @thread = Thread.new do
          while readable_io = IO.select([read_io]) # rubocop:disable AssignmentInCondition
            signal = readable_io.first[0].gets.strip

            case signal
            when 'HUP'
              Synchronizer.sync
              Feeder.wakeup
            when 'USR2'
              AppRunner.debug
            when 'INT', 'TERM'
              Thread.new { Rpush::Daemon.shutdown }
              break
            when 'break'
              break
            else
              Rpush.logger.error("Unhandled signal: #{signal}")
            end
          end
        end
      end

      def self.trap_signals?
        !Rpush.config.embedded
      end
    end
  end
end
