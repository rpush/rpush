# encoding: UTF-8

require 'thor'
require 'ansi/code'

module Rpush
  class CLI < Thor
    def self.detect_rails?
      ['bin/rails', 'script/rails'].any? { |path| File.exist?(path) }
    end

    def self.default_config_path
      detect_rails? ? 'config/initializers/rpush.rb' : 'config/rpush.rb'
    end

    class_option :config, type: :string, aliases: '-c', default: default_config_path
    class_option 'rails-env', type: :string, aliases: '-e', default: 'development'

    option :foreground, type: :boolean, aliases: '-f', default: false
    option 'pid-file', type: :string, aliases: '-p'
    desc 'start', 'Start Rpush'
    def start
      config_setup

      require 'rpush/daemon'
      Rpush::Daemon.start
    end

    desc 'stop', 'Stop Rpush'
    option 'pid-file', type: :string, aliases: '-p'
    def stop
      config_setup
      ensure_pid_file_set

      if File.exist?(Rpush.config.pid_file)
        pid = File.read(Rpush.config.pid_file).strip.to_i
        STDOUT.write "* Stopping Rpush (pid #{pid})... "
        STDOUT.flush
        Process.kill('TERM', pid)

        loop do
          begin
            Process.getpgid(pid)
            sleep 0.05
          rescue Errno::ESRCH
            break
          end
        end

        puts ANSI.green { '✔' }
      else
        STDERR.puts("* Rpush isn't running? #{Rpush.config.pid_file} does not exist.")
        return
      end
    end

    desc 'init', 'Initialize Rpush into the current directory'
    option 'active-record', type: :boolean, desc: 'Install ActiveRecord migrations'
    def init
      underscore_option_names
      check_ruby_version
      require 'rails/generators'

      puts "* " + ANSI.green { 'Installing config...' }
      $RPUSH_CONFIG_PATH = default_config_path # rubocop:disable Style/GlobalVars
      Rails::Generators.invoke('rpush_config')

      install_migrations = options['active_record']

      unless options.key?('active_record')
        has_answer = false
        until has_answer
          STDOUT.write "\n* #{ANSI.green { 'Install ActiveRecord migrations?' }} [y/n]: "
          STDOUT.flush
          answer = STDIN.gets.chomp.downcase
          has_answer = %w(y n).include?(answer)
        end

        install_migrations = answer == 'y'
      end

      Rails::Generators.invoke('rpush_migration', ['--force']) if install_migrations

      puts "\n* #{ANSI.green { 'Next steps:' }}"
      puts "  - Run 'db:migrate'." if install_migrations
      puts "  - Review and update your configuration in #{default_config_path}."
      puts "  - Create your first app, see https://github.com/rpush/rpush for examples."
      puts "  - Run 'rpush help' for commands and options."
    end

    desc 'push', 'Deliver all pending notifications and then exit'
    def push
      config_setup
      Rpush.config.foreground = true

      Rpush.push
    end

    desc 'version', 'Print Rpush version'
    def version
      puts Rpush::VERSION
    end

    private

    def config_setup
      underscore_option_names
      check_ruby_version
      configure_rpush
    end

    def configure_rpush
      load_rails_environment || load_standalone
    end

    def load_rails_environment
      if detect_rails? && options['rails_env']
        STDOUT.write "* Booting Rails '#{options[:rails_env]}' environment... "
        STDOUT.flush
        ENV['RAILS_ENV'] = options['rails_env']
        load 'config/environment.rb'
        Rpush.config.update(options)
        puts ANSI.green { '✔' }

        return true
      end

      false
    end

    def load_standalone
      if !File.exist?(options[:config])
        STDERR.puts(ANSI.red { 'ERROR: ' } + "#{options[:config]} does not exist. Please run 'rpush init' to generate it or specify the --config option.")
        exit 1
      else
        load options[:config]
        Rpush.config.update(options)
      end
    end

    def detect_rails?
      self.class.detect_rails?
    end

    def default_config_path
      self.class.default_config_path
    end

    def ensure_pid_file_set
      return unless Rpush.config.pid_file.blank?

      STDERR.puts(ANSI.red { 'ERROR: ' } + 'config.pid_file is not set.')
      exit 1
    end

    def check_ruby_version
      STDERR.puts(ANSI.yellow { 'WARNING: ' } + "You are using an old and unsupported version of Ruby.") if RUBY_VERSION <= '1.9.3' && RUBY_ENGINE == 'ruby'
    end

    def underscore_option_names
      # Underscore option names so that they map directly to Configuration options.
      new_options = options.dup

      options.each do |k, v|
        new_k = k.to_s.tr('-', '_')

        if k != new_k
          new_options.delete(k)
          new_options[new_k] = v
        end
      end

      new_options.freeze
      self.options = new_options
    end
  end
end
