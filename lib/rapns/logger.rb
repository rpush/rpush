module Rapns
  class Logger
    def initialize(options)
      @options = options

      begin
        log = File.open(File.join(Rails.root, 'log', 'rapns.log'), 'a')
        log.sync = true
        setup_logger(log)
      rescue Errno::ENOENT, Errno::EPERM => e
        @logger = nil
        error(e)
        error('Logging disabled.')
      end
    end

    def info(msg)
      log(:info, msg)
    end

    def error(msg, options = {})
      airbrake_notify(msg) if notify_via_airbrake?(msg, options)
      log(:error, msg, 'ERROR', STDERR)
    end

    def warn(msg)
      log(:warn, msg, 'WARNING', STDERR)
    end

    private

    def setup_logger(log)
      if Rapns.config.logger
        @logger = Rapns.config.logger
      elsif ActiveSupport.const_defined?('BufferedLogger')
        @logger = ActiveSupport::BufferedLogger.new(log, Rails.logger.level)
        @logger.auto_flushing = Rails.logger.respond_to?(:auto_flushing) ? Rails.logger.auto_flushing : true
      else
        @logger = ActiveSupport::Logger.new(log, Rails.logger.level)
      end
    end

    def log(where, msg, prefix = nil, io = STDOUT)
      if msg.is_a?(Exception)
        formatted_backtrace = msg.backtrace.join("\n")
        msg = "#{msg.class.name}, #{msg.message}\n#{formatted_backtrace}"
      end

      formatted_msg = "[#{Time.now.to_s(:db)}] "
      formatted_msg << "[#{prefix}] " if prefix
      formatted_msg << msg

      if io == STDERR
        io.puts formatted_msg
      elsif @options[:foreground]
        io.puts formatted_msg
      end

      @logger.send(where, formatted_msg) if @logger
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
