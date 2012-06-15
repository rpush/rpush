module Rapns
  module Daemon
    class Logger
      def initialize(options)
        @options = options
        log = File.open(File.join(Rails.root, 'log', 'rapns.log'), 'w')
        log.sync = true
        @logger = ActiveSupport::BufferedLogger.new(log, Rails.logger.level)
        @logger.auto_flushing = Rails.logger.respond_to?(:auto_flushing) ? Rails.logger.auto_flushing : true
      end

      def info(msg)
        log(:info, msg)
      end

      def error(msg, options = {})
        airbrake_notify(msg) if notify_via_airbrake?(msg, options)
        log(:error, msg, 'ERROR')
      end

      def warn(msg)
        log(:warn, msg, 'WARNING')
      end

      private

      def log(where, msg, prefix = nil)
        if msg.is_a?(Exception)
          formatted_backtrace = msg.backtrace.join("\n")
          msg = "#{msg.class.name}, #{msg.message}\n#{formatted_backtrace}"
        end

        formatted_msg = "[#{Time.now.to_s(:db)}] "
        formatted_msg << "[#{prefix}] " if prefix
        formatted_msg << msg
        puts formatted_msg if @options[:foreground]
        @logger.send(where, formatted_msg)
      end

      def airbrake_notify(e)
        return unless @options[:airbrake_notify] == true

        if defined?(Airbrake)
          Airbrake.notify_or_ignore(e)
        elsif defined?(HoptoadNotifier)
          HoptoadNotifier.notify_or_ignore(e)
        end
      end

      def notify_via_airbrake?(msg, options)
        msg.is_a?(Exception) && options[:airbrake_notify] != false
      end
    end
  end
end