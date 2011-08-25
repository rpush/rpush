require "rapns/daemon/configuration"
require "rapns/daemon/certificate"
require "rapns/daemon/connection"
require "rapns/daemon/runner"
require "rapns/daemon/logger"

module Rapns
  def self.logger
    @logger
  end

  module Daemon
    def self.start(environment, options)
      Rapns.instance_variable_set("@logger", Logger.new(options[:foreground]))
      Configuration.load(environment, File.join(Rails.root, "config", "rapns", "rapns.yml"))
      Certificate.load(Configuration.certificate)
      Connection.connect
      fork unless options[:foreground]
      Runner.start(options)
    end

    protected

    def self.fork
      exit if pid = fork
      Process.setsid
      exit if pid = fork

      Dir.chdir '/'
      File.umask 0000

      STDIN.reopen '/dev/null'
      STDOUT.reopen '/dev/null', 'a'
      STDERR.reopen STDOUT
    end
  end
end