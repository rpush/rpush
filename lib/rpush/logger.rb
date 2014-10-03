module Rpush
  class Logger
    def initialize
      FileUtils.mkdir_p(File.dirname(Rpush.config.log_file))
      log = File.open(Rpush.config.log_file, 'a')
      log.sync = true
      setup_logger(log)
    rescue Errno::ENOENT, Errno::EPERM => e
      @logger = nil
      error(e)
      error('Logging disabled.')
    end

    def info(msg, inline = false)
      log(:info, msg, inline)
    end

    def error(msg, inline = false)
      log(:error, msg, inline, 'ERROR', STDERR)
    end

    def warn(msg, inline = false)
      log(:warn, msg, inline, 'WARNING', STDERR)
    end

    private

    def setup_logger(log)
      if Rpush.config.logger
        @logger = Rpush.config.logger
      elsif ActiveSupport.const_defined?('BufferedLogger')
        @logger = ActiveSupport::BufferedLogger.new(log, Rpush.config.log_level)
        @logger.auto_flushing = auto_flushing
      else
        @logger = ActiveSupport::Logger.new(log, Rpush.config.log_level)
      end
    end

    def auto_flushing
      if defined?(Rails) && Rails.logger.respond_to?(:auto_flushing)
        Rails.logger.auto_flushing
      else
        true
      end
    end

    def log(where, msg, inline = false, prefix = nil, io = STDOUT)
      if msg.is_a?(Exception)
        formatted_backtrace = msg.backtrace.join("\n")
        msg = "#{msg.class.name}, #{msg.message}\n#{formatted_backtrace}"
      end

      formatted_msg = "[#{Time.now.to_s(:db)}] "
      formatted_msg << "[#{prefix}] " if prefix
      formatted_msg << msg

      log_foreground(io, formatted_msg, inline)
      @logger.send(where, formatted_msg) if @logger
    end

    def log_foreground(io, formatted_msg, inline)
      return unless io == STDERR || Rpush.config.foreground

      if inline
        io.write(formatted_msg)
        io.flush
      else
        io.puts(formatted_msg)
      end
    end
  end
end
