require "rapns/daemon/configuration"
require "rapns/daemon/certificate"
require "rapns/daemon/connection_pool"
require "rapns/daemon/connection"
require "rapns/daemon/runner"
require "rapns/daemon/logger"

module Rapns
  module Daemon
    class << self
      attr_accessor :logger, :configuration, :certificate, :connection_pool
    end

    def self.start(environment, options)
      setup_signal_hooks

      self.logger = Logger.new(options[:foreground])

      self.configuration = Configuration.new(environment, File.join(Rails.root, "config", "rapns", "rapns.yml"))
      configuration.load

      self.certificate = Certificate.new(configuration.certificate)
      certificate.load

      self.connection_pool = ConnectionPool.new
      connection_pool.populate

      daemonize unless options[:foreground]

      Runner.start(options)
    end

    protected

    def self.setup_signal_hooks
      Signal.trap("SIGINT") { shutdown }
    end

    def self.shutdown
      puts "\nShutting down..."
      Rapns::Daemon::Runner.stop
      Rapns::Daemon.connection_pool.drain if Rapns::Daemon.connection_pool
    end

    def self.daemonize
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