require 'thread'
require 'socket'
require 'pathname'
require 'openssl'

require 'net/http/persistent'

require 'rapns/daemon/interruptible_sleep'
require 'rapns/daemon/delivery_error'
require 'rapns/daemon/database_reconnectable'
require 'rapns/daemon/delivery'
require 'rapns/daemon/delivery_queue'
require 'rapns/daemon/feeder'
require 'rapns/daemon/logger'
require 'rapns/daemon/app_runner'
require 'rapns/daemon/delivery_handler'

require 'rapns/daemon/apns/delivery'
require 'rapns/daemon/apns/disconnection_error'
require 'rapns/daemon/apns/connection'
require 'rapns/daemon/apns/app_runner'
require 'rapns/daemon/apns/delivery_handler'
require 'rapns/daemon/apns/feedback_receiver'

require 'rapns/daemon/gcm/delivery'
require 'rapns/daemon/gcm/app_runner'
require 'rapns/daemon/gcm/delivery_handler'

module Rapns
  module Daemon
    extend DatabaseReconnectable

    class << self
      attr_accessor :logger
    end

    def self.start
      self.logger = Logger.new(:foreground => Rapns.config.foreground,
                               :airbrake_notify => Rapns.config.airbrake_notify)

      setup_signal_hooks unless Rapns.config.embedded

      unless Rapns.config.foreground || Rapns.config.embedded
        daemonize
        reconnect_database
      end

      write_pid_file
      ensure_upgraded
      AppRunner.sync

      if Rapns.config.embedded
        Thread.new { start_feeder }
      else
        start_feeder
      end
    end

    def self.shutdown
      puts "\nShutting down..."
      Feeder.stop
      AppRunner.stop
      delete_pid_file
    end

    protected

    def self.start_feeder
      Feeder.start(Rapns.config.push_poll)
    end

    def self.ensure_upgraded
      count = 0

      begin
        count = Rapns::App.count
      rescue ActiveRecord::StatementInvalid
        puts "!!!! RAPNS NOT STARTED !!!!"
        puts
        puts "As of version v2.0.0 apps are configured in the database instead of rapns.yml."
        puts "Please run 'rails g rapns' to generate the new migrations and create your app."
        puts "See https://github.com/ileitch/rapns for further instructions."
        puts
        exit 1
      end

      if count == 0
        logger.warn("You have not created an app yet. See https://github.com/ileitch/rapns for instructions.")
      end

      if File.exists?(File.join(Rails.root, 'config', 'rapns', 'rapns.yml'))
        logger.warn(<<-EOS)
Since 2.0.0 rapns uses command-line options and a Ruby based configuration file.
Please run 'rails g rapns' to generate a new configuration file into config/initializers.
Remove config/rapns/rapns.yml to avoid this warning.
        EOS
      end
    end

    def self.setup_signal_hooks
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
          logger.error("Failed to write PID to '#{Rapns.config.pid_file}': #{e.inspect}")
        end
      end
    end

    def self.delete_pid_file
      pid_file = Rapns.config.pid_file
      File.delete(pid_file) if !pid_file.blank? && File.exists?(pid_file)
    end

    # :nocov:
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
