require 'thread'
require 'socket'
require 'pathname'

require 'rapns/daemon/interruptible_sleep'
require 'rapns/daemon/configuration'
require 'rapns/daemon/delivery_error'
require 'rapns/daemon/disconnection_error'
require 'rapns/daemon/connection'
require 'rapns/daemon/database_reconnectable'
require 'rapns/daemon/delivery_queue'
require 'rapns/daemon/delivery_handler'
require 'rapns/daemon/delivery_handler_pool'
require 'rapns/daemon/feedback_receiver'
require 'rapns/daemon/app_runner'
require 'rapns/daemon/feeder'
require 'rapns/daemon/logger'

module Rapns
  module Daemon
    extend DatabaseReconnectable

    class << self
      attr_accessor :logger, :configuration
    end

    def self.start(environment, foreground)
      setup_signal_hooks

      self.configuration = Configuration.load(environment, File.join(Rails.root, 'config', 'rapns', 'rapns.yml'))
      self.logger = Logger.new(:foreground => foreground, :airbrake_notify => configuration.airbrake_notify)

      unless foreground
        daemonize
        reconnect_database
      end

      write_pid_file
      ensure_upgraded
      AppRunner.sync
      Feeder.start(configuration.push.poll)
    end

    protected

    def self.ensure_upgraded
      count = 0

      begin
        count = Rapns::App.count
      rescue ActiveRecord::StatementInvalid
        puts "!!!! RAPNS NOT STARTED !!!!"
        puts
        puts "As of version v2.0.0 apps are configured in the database instead of rapns.yml."
        puts "Please run 'rails g rapns' to generate the new migrations and create your apps with Rapns::App."
        puts "See https://github.com/ileitch/rapns for further instructions."
        puts
        exit 1
      end

      if count == 0
        puts "!!!! RAPNS NOT STARTED !!!!"
        puts
        puts "You must create an Rapns::App."
        puts "See https://github.com/ileitch/rapns for instructions."
        puts
        exit 1
      end
    end

    def self.setup_signal_hooks
      @shutting_down = false

      Signal.trap('SIGHUP') { AppRunner.sync }
      Signal.trap('SIGUSR1') { AppRunner.debug }

      ['SIGINT', 'SIGTERM'].each do |signal|
        Signal.trap(signal) { handle_shutdown_signal }
      end
    end

    def self.handle_shutdown_signal
      exit 1 if @shutting_down
      @shutting_down = true
      shutdown
    end

    def self.shutdown
      puts "\nShutting down..."
      Feeder.stop
      AppRunner.stop
      delete_pid_file
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
      if !configuration.pid_file.blank?
        begin
          File.open(configuration.pid_file, 'w') { |f| f.puts Process.pid }
        rescue SystemCallError => e
          logger.error("Failed to write PID to '#{configuration.pid_file}': #{e.inspect}")
        end
      end
    end

    def self.delete_pid_file
      pid_file = configuration.pid_file
      File.delete(pid_file) if !pid_file.blank? && File.exists?(pid_file)
    end
  end
end