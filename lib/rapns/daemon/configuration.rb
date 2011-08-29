require "yaml"

module Rapns
  class ConfigurationError < Exception; end

  module Daemon
    class Configuration
      attr_accessor :host, :port, :certificate, :certificate_password

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
        set_variable(:airbrake_notify, config, :optional => true)
        set_variable(:certificate_password, config, :optional => true)
      end

      def certificate
        if Pathname.new(@certificate).absolute?
          @certificate
        else
          File.join(Rails.root, "config", "rapns", @certificate)
        end
      end

      def certificate_password
        @certificate_password.blank? ? "" : @certificate_password
      end

      def airbrake_notify?
        @airbrake_notify == true
      end

      protected

      def read_config
        ensure_config_exists
        File.open(@config_path) { |fd| YAML.load(fd) }
      end

      def set_variable(key, config, options = {})
        if config[key.to_s].blank?
          if !options[:optional]
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