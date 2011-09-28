require "yaml"

module Rapns
  class ConfigurationError < StandardError; end

  module Daemon
    class Configuration
      attr_accessor :host, :port, :certificate, :certificate_password, :poll, :airbrake_notify, :connections, :pid_file
      alias_method  :airbrake_notify?, :airbrake_notify

      def initialize(environment, config_path)
        @environment = environment
        @config_path = config_path
      end

      def load
        config = read_config
        ensure_environment_configured(config)
        config = config[@environment]
        set_variable(:host, config)
        set_variable(:port, config)
        set_variable(:certificate, config)
        set_variable(:airbrake_notify, config, :optional => true, :default => true)
        set_variable(:certificate_password, config, :optional => true, :default => "")
        set_variable(:poll, config, :optional => true, :default => 2)
        set_variable(:connections, config, :optional => true, :default => 3)
        set_variable(:pid_file, config, :optional => true, :default => "")
      end

      def certificate
        if Pathname.new(@certificate).absolute?
          @certificate
        else
          File.join(Rails.root, "config", "rapns", @certificate)
        end
      end

      def pid_file
        return if @pid_file.blank?

        if Pathname.new(@pid_file).absolute?
          @pid_file
        else
          File.join(Rails.root, @pid_file)
        end
      end

      protected

      def read_config
        ensure_config_exists
        File.open(@config_path) { |fd| YAML.load(fd) }
      end

      def set_variable(key, config, options = {})
        if !config.key?(key.to_s) || config[key.to_s].to_s.strip == ""
          if options[:optional]
            instance_variable_set("@#{key}", options[:default])
          else
            raise Rapns::ConfigurationError, "'#{key}' not defined for environment '#{@environment}' in #{@config_path}"
          end
        else
          instance_variable_set("@#{key}", config[key.to_s])
        end
      end

      def ensure_config_exists
        if !File.exists?(@config_path)
          raise Rapns::ConfigurationError, "#{@config_path} does not exist. Have you run 'rails g rapns'?"
        end
      end

      def ensure_environment_configured(config)
        if !config.key?(@environment)
          raise Rapns::ConfigurationError, "Configuration for environment '#{@environment}' not defined in #{@config_path}"
        end
      end
    end
  end
end