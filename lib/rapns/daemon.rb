require 'thread'
require 'socket'
require 'pathname'
require 'openssl'

require 'net/http/persistent'

require 'rapns/daemon/reflectable'
require 'rapns/daemon/interruptible_sleep'
require 'rapns/daemon/delivery_error'
require 'rapns/daemon/delivery'
require 'rapns/daemon/feeder'
require 'rapns/daemon/batch'
require 'rapns/daemon/app_runner'
require 'rapns/daemon/delivery_handler'
require 'rapns/daemon/delivery_handler_collection'

require 'rapns/daemon/apns/delivery'
require 'rapns/daemon/apns/disconnection_error'
require 'rapns/daemon/apns/certificate_expired_error'
require 'rapns/daemon/apns/connection'
require 'rapns/daemon/apns/app_runner'
require 'rapns/daemon/apns/delivery_handler'
require 'rapns/daemon/apns/feedback_receiver'

require 'rapns/daemon/gcm/delivery'
require 'rapns/daemon/gcm/app_runner'
require 'rapns/daemon/gcm/delivery_handler'

module Rapns
  module Daemon
    class << self
      attr_accessor :store
    end

    def self.start
      setup_signal_traps if trap_signals?

      initialize_store
      return unless store

      if daemonize?
        daemonize
        store.after_daemonize
      end

      write_pid_file
      Upgraded.check(:exit => true)
      AppRunner.sync
      Feeder.start
    end

    def self.shutdown(quiet = false)
      puts "\nShutting down..." unless quiet
      Feeder.stop
      AppRunner.stop
      delete_pid_file
    end

    def self.initialize_store
      return if store
      begin
        require "rapns/daemon/store/#{Rapns.config.store}"
        klass = "Rapns::Daemon::Store::#{Rapns.config.store.to_s.camelcase}".constantize
        self.store = klass.new
      rescue StandardError, LoadError => e
        Rapns.logger.error("Failed to load '#{Rapns.config.store}' storage backend.")
        Rapns.logger.error(e)
      end
    end

    protected

    def self.daemonize?
      !(Rapns.config.foreground || Rapns.config.embedded || Rapns.jruby?)
    end

    def self.trap_signals?
      !Rapns.config.embedded
    end

    def self.setup_signal_traps
      @shutting_down = false

      Signal.trap('SIGHUP') { AppRunner.sync }
      Signal.trap('SIGUSR2') { AppRunner.debug }

      ['SIGINT', 'SIGTERM'].each do |signal|
        Signal.trap(signal) { handle_shutdown_signal }
      end
    end

    def self.handle_shutdown_signal
      exit 1 if @shutting_down
      @shutting_down = true
      shutdown
    end

    def self.write_pid_file
      if !Rapns.config.pid_file.blank?
        begin
          File.open(Rapns.config.pid_file, 'w') { |f| f.puts Process.pid }
        rescue SystemCallError => e
          Rapns.logger.error("Failed to write PID to '#{Rapns.config.pid_file}': #{e.inspect}")
        end
      end
    end

    def self.delete_pid_file
      pid_file = Rapns.config.pid_file
      File.delete(pid_file) if !pid_file.blank? && File.exists?(pid_file)
    end

    # :nocov:
    def self.daemonize
      if RUBY_VERSION < "1.9"
        exit if fork
        Process.setsid
        exit if fork
        Dir.chdir "/"
        STDIN.reopen "/dev/null"
        STDOUT.reopen "/dev/null", "a"
        STDERR.reopen "/dev/null", "a"
      else
        Process.daemon
      end
    end
  end
end
