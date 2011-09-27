require "rapns/daemon/configuration"
require "rapns/daemon/certificate"
require "rapns/daemon/delivery_error"
require "rapns/daemon/pool"
require "rapns/daemon/connection_pool"
require "rapns/daemon/connection"
require "rapns/daemon/delivery_queue"
require "rapns/daemon/delivery_handler"
require "rapns/daemon/delivery_handler_pool"
require "rapns/daemon/feeder"
require "rapns/daemon/logger"

module Rapns
  module Daemon
    class << self
      attr_accessor :logger, :configuration, :certificate, :connection_pool, :delivery_queue,
        :delivery_handler_pool, :foreground, :pid_file
      alias_method  :foreground?, :foreground
    end

    def self.start(environment, foreground)
      @foreground = foreground
      setup_signal_hooks

      self.configuration = Configuration.new(environment, File.join(Rails.root, "config", "rapns", "rapns.yml"))
      configuration.load

      self.logger = Logger.new(:foreground => foreground, :airbrake_notify => configuration.airbrake_notify)

      self.certificate = Certificate.new(configuration.certificate)
      certificate.load

      self.delivery_queue = DeliveryQueue.new

      unless foreground?
        daemonize
        ActiveRecord::Base.establish_connection
      end

      write_pid_file unless configuration.pid_file.blank?

      self.delivery_handler_pool = DeliveryHandlerPool.new(configuration.connections)
      delivery_handler_pool.populate

      self.connection_pool = ConnectionPool.new(configuration.connections)
      connection_pool.populate

      Feeder.start
    end

    protected

    def self.setup_signal_hooks
      @shutting_down = false
      Signal.trap("SIGINT") do
        exit 1 if @shutting_down
        @shutting_down = true
        shutdown
      end
      Signal.trap("SIGTERM") do
        exit 1 if @shutting_down
        @shutting_down = true
        shutdown
      end
    end

    def self.shutdown
      puts "\nShutting down..."
      Rapns::Daemon::Feeder.stop
      Rapns::Daemon.delivery_handler_pool.drain if Rapns::Daemon.delivery_handler_pool
      Rapns::Daemon.connection_pool.drain if Rapns::Daemon.connection_pool
      File.delete(pid_file) unless pid_file.blank?
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
    
    def self.write_pid_file
      pid_file = if Pathname.new(configuration.pid_file).absolute?
        configuration.pid_file
      else
        File.join(Rails.root, configuration.pid_file)
      end
      
      File.open(pid_file, "w") do |f|
        f.puts $$
      end
      
      self.pid_file = pid_file
    end
  end
end