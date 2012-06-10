require 'yaml'

module Rapns
  class ConfigurationError < StandardError; end

  module Daemon
    class Configuration
      attr_accessor :push, :feedback, :apps
      attr_accessor :airbrake_notify, :pid_file
      alias_method  :airbrake_notify?, :airbrake_notify

      def initialize(environment, config_path)
        @environment = environment
        @config_path = config_path
        @app_template = Struct.new(:certificate, :certificate_password, :connections)

        self.push = Struct.new(:host, :port, :poll).new
        self.feedback = Struct.new(:host, :port, :poll).new
        self.apps = {}
      end

      def load
        config = read_config
        ensure_environment_configured(config)
        config = config[@environment]

        load_push(config)
        load_feedback(config)
        load_defaults(config)

        (config.keys - ['push', 'feedback']).each do |app|
          if config[app].kind_of? Hash
            load_app(app, config)
          end
        end
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
      end

      def load_app(name, config)
        app = @app_template.new
        apps[name] = app
        set_variable(app, name, :certificate, config, :path => rapns_root)
        set_variable(app, name, :certificate_password, config, :optional => true, :default => "")
        set_variable(app, name, :connections, config, :optional => true, :default => 3)
      end

      protected

      def rapns_root
        File.join(Rails.root, 'config', 'rapns')
      end

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