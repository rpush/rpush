require "yaml"

module Rapns
  class ConfigurationError < Exception; end

  module Daemon
    class Configuration
      def self.load(environment, config_path)
        config = read_config(environment, config_path)
        ensure_environment_configured(environment, config, config_path)
        config = config[environment]
        set_variable(:host, config, environment, config_path)
        set_variable(:port, config, environment, config_path)
        set_variable(:certificate, config, environment, config_path)
      end

      def self.host
        @host
      end

      def self.port
        @port
      end

      def self.certificate
        File.join(Rails.root, "config", "rapns", @certificate)
      end

      protected

      def self.read_config(environment, config_path)
        ensure_config_exists(config_path)
        File.open(config_path) { |fd| YAML.load(fd) }
      end

      def self.set_variable(key, config, environment, config_path)
        if config[key.to_s].blank?
          raise Rapns::ConfigurationError, "'#{key}' not specified for environment '#{environment}' in #{config_path}"
        else
          instance_variable_set("@#{key}", config[key.to_s])
        end
      end

      def self.ensure_config_exists(config_path)
        if !File.exists?(config_path)
          raise Rapns::ConfigurationError, "#{config_path} does not exist. Have you run 'rails g rapns'?"
        end
      end

      def self.ensure_environment_configured(environment, config, config_path)
        if !config.key?(environment)
          raise Rapns::ConfigurationError, "Configuration for environment '#{environment}' not specified in #{config_path}"
        end
      end
    end
  end
end