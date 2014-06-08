require 'thread'
require 'socket'
require 'pathname'
require 'openssl'
require 'net/http/persistent'

require 'rpush/daemon/errors'
require 'rpush/daemon/constants'
require 'rpush/daemon/reflectable'
require 'rpush/daemon/loggable'
require 'rpush/daemon/interruptible_sleep'
require 'rpush/daemon/delivery_error'
require 'rpush/daemon/retryable_error'
require 'rpush/daemon/too_many_requests_error'
require 'rpush/daemon/delivery'
require 'rpush/daemon/feeder'
require 'rpush/daemon/batch'
require 'rpush/daemon/queue_payload'
require 'rpush/daemon/app_runner'
require 'rpush/daemon/tcp_connection'
require 'rpush/daemon/dispatcher_loop'
require 'rpush/daemon/dispatcher_loop_collection'
require 'rpush/daemon/dispatcher/http'
require 'rpush/daemon/dispatcher/tcp'
require 'rpush/daemon/dispatcher/batched_tcp'
require 'rpush/daemon/service_config_methods'
require 'rpush/daemon/retry_header_parser'

require 'rpush/daemon/store/interface'

require 'rpush/daemon/apns/delivery'
require 'rpush/daemon/apns/feedback_receiver'
require 'rpush/daemon/apns'

require 'rpush/daemon/gcm/delivery'
require 'rpush/daemon/gcm'

require 'rpush/daemon/wpns/delivery'
require 'rpush/daemon/wpns'

require 'rpush/daemon/adm/delivery'
require 'rpush/daemon/adm'

module Rpush
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
        name = Rpush.config.client.to_s
        require "rpush/daemon/store/#{name}"
        self.store = Rpush::Daemon::Store.const_get(name.camelcase).new
      rescue StandardError, LoadError => e
        Rpush.logger.error("Failed to load '#{Rpush.config.client}' storage backend.")
        Rpush.logger.error(e)
      end
    end

    protected

    def self.daemonize?
      !(Rpush.config.push || Rpush.config.foreground || Rpush.config.embedded || Rpush.jruby?)
    end

    def self.trap_signals?
      !Rpush.config.embedded
    end

    def self.setup_signal_traps
      @shutting_down = false
      read_io, write_io = IO.pipe
      start_signal_handler(read_io)
      %w(INT TERM HUP USR2).each do |signal|
        Signal.trap(signal) { write_io.write("#{Signal.list[signal]}\n") }
      end
    end

    def self.start_signal_handler(read_io)
      Thread.new do
        loop do
          case read_io.readline.strip.to_i
          when Signal.list['HUP']
            AppRunner.sync
          when Signal.list['USR2']
            AppRunner.debug
          when Signal.list['INT'], Signal.list['TERM']
            handle_shutdown_signal
          end
        end
      end
    end

    def self.handle_shutdown_signal
      exit 1 if @shutting_down
      @shutting_down = true
      shutdown
    end

    def self.write_pid_file
      unless Rpush.config.pid_file.blank?
        begin
          File.open(Rpush.config.pid_file, 'w') { |f| f.puts Process.pid }
        rescue SystemCallError => e
          Rpush.logger.error("Failed to write PID to '#{Rpush.config.pid_file}': #{e.inspect}")
        end
      end
    end

    def self.delete_pid_file
      pid_file = Rpush.config.pid_file
      File.delete(pid_file) if !pid_file.blank? && File.exist?(pid_file)
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
