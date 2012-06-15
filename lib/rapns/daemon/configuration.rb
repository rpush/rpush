require 'yaml'

module Rapns
  class ConfigurationError < StandardError; end

  module Daemon
    class Configuration
      attr_accessor :push, :feedback
      attr_accessor :airbrake_notify, :pid_file, :check_for_errors, :feeder_batch_size

      def self.load(environment, config_path)
        configuration = new(environment, config_path)
        configuration.load
        configuration
      end

      def initialize(environment, config_path)
        @environment = environment
        @config_path = config_path

        self.push = Struct.new(:host, :port, :poll).new
        self.feedback = Struct.new(:host, :port, :poll).new
      end

      def load
        config = read_config
        ensure_environment_configured(config)
        config = config[@environment]

        load_push(config)
        load_feedback(config)
        load_defaults(config)
      end

      def load_push(config)
        set_variable(push, :push, :host, config)
        set_variable(push, :push, :port, config)
        set_variable(push, :push, :poll, config, :optional => true, :default => 2)
      end

      def load_feedback(config)
        set_variable(feedback, :feedback, :host, config)
        set_variable(feedback ,:feedback, :port, config)
        set_variable(feedback, :feedback, :poll, config, :optional => true, :default => 60)
      end

      def load_defaults(config)
        set_variable(self, nil, :airbrake_notify, config, :optional => true, :default => true)
        set_variable(self, nil, :pid_file, config, :optional => true, :default => nil, :path => Rails.root)
        set_variable(self, nil, :check_for_errors, config, :optional => true, :default => true)
        set_variable(self, nil, :feeder_batch_size, config, :optional => true, :default => 5000)
      end

      protected

      def read_config
        ensure_config_exists
        File.open(@config_path) { |fd| YAML.load(fd) }
      end

      def set_variable(base, base_key, key, config, options = {})
        if base_key
          value = config.key?(base_key.to_s) ? config[base_key.to_s][key.to_s] : nil
        else
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
          value = File.join(options[:path], value) if options[:path] && !Pathname.new(value).absolute?
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