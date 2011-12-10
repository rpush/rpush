require "yaml"

module Rapns
  class ConfigurationError < StandardError; end

  module Daemon
    class Configuration
      attr_accessor :push, :feedback
      attr_accessor :certificate, :certificate_password, :airbrake_notify, :pid_file
      alias_method  :airbrake_notify?, :airbrake_notify

      def initialize(environment, config_path)
        @environment = environment
        @config_path = config_path

        self.push = Struct.new(:host, :port, :connections, :poll).new
        self.feedback = Struct.new(:host, :port, :poll).new
      end

      def load
        config = read_config
        ensure_environment_configured(config)
        config = config[@environment]
        set_variable(:push, :host, config)
        set_variable(:push, :port, config)
        set_variable(:push, :poll, config, :optional => true, :default => 2)
        set_variable(:push, :connections, config, :optional => true, :default => 3)

        set_variable(:feedback, :host, config)
        set_variable(:feedback, :port, config)
        set_variable(:feedback, :poll, config, :optional => true, :default => 60)

        set_variable(nil, :certificate, config)
        set_variable(nil, :airbrake_notify, config, :optional => true, :default => true)
        set_variable(nil, :certificate_password, config, :optional => true, :default => "")
        set_variable(nil, :pid_file, config, :optional => true, :default => "")
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

      def set_variable(base_key, key, config, options = {})
        if base_key
          base = send(base_key)
          value = config.key?(base_key.to_s) ? config[base_key.to_s][key.to_s] : nil
        else
          base = self
          value = config[key.to_s]
        end

        if value.to_s.strip == ""
          if options[:optional]
            base.send("#{key}=", options[:default])
          else
            key_path = base_key ? "#{base_key}.#{key}" : key
            raise Rapns::ConfigurationError, "'#{key_path}' not defined for environment '#{@environment}' in #{@config_path}. You may need to run 'rails g rapns' after updating."
          end
        else
          base.send("#{key}=", value)
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