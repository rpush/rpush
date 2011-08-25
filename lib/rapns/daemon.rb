require "rapns/daemon/configuration"
require "rapns/daemon/certificate"
require "rapns/daemon/connection"
require "rapns/daemon/runner"

module Rapns
  def self.logger
    @logger
  end

  module Daemon
    def self.start(environment, options)
      setup_logger
      Configuration.load(environment, File.join(Rails.root, "config", "rapns", "rapns.yml"))
      Certificate.load(Configuration.certificate)
      Connection.connect
      fork unless options[:foreground]
      Runner.start(options)
    end

    protected

    def self.fork
      fork && exit
      Process.setsid
      fork && exit

      Dir.chdir '/'
      File.umask 0000

      STDIN.reopen '/dev/null'
      STDOUT.reopen '/dev/null', 'a'
      STDERR.reopen STDOUT
    end

    def self.setup_logger
      log_path = File.join(Rails.root, "log", "rapns.log")
      logger = ActiveSupport::BufferedLogger.new(log_path, Rails.logger.level)
      logger.auto_flushing = Rails.logger.auto_flushing
      Rapns.instance_variable_set("@logger", logger)
    end
  end
end