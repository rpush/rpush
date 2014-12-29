require 'pathname'

module Rpush
  def self.config
    @config ||= Rpush::Configuration.new
  end

  def self.configure
    if block_given?
      yield config
      config.initialize_client
    end
  end

  CURRENT_ATTRS = [:push_poll, :feedback_poll, :embedded, :pid_file, :batch_size,
                   :push, :client, :logger, :log_file, :foreground, :log_level, :plugin]
  DEPRECATED_ATTRS = [:log_dir]
  CONFIG_ATTRS = CURRENT_ATTRS + DEPRECATED_ATTRS

  class ConfigurationError < StandardError; end
  class ConfigurationWithoutDefaults < Struct.new(*CONFIG_ATTRS); end

  class Configuration < Struct.new(*CONFIG_ATTRS)
    include Deprecatable

    deprecated(:log_dir=, '2.3.0', 'Please use log_file instead.')

    delegate :redis_options, to: '::Modis'

    def initialize
      super
      set_defaults
    end

    def update(other)
      CONFIG_ATTRS.each do |attr|
        other_value = other.send(attr)
        send("#{attr}=", other_value) unless other_value.nil?
      end
    end

    def pid_file=(path)
      if path && !Pathname.new(path).absolute?
        super(File.join(Rpush.root, path))
      else
        super
      end
    end

    def log_file=(path)
      if path && !Pathname.new(path).absolute?
        super(File.join(Rpush.root, path))
      else
        super
      end
    end

    def logger=(logger)
      super(logger)
    end

    def client=(client)
      super
      initialize_client
    end

    def redis_options=(options)
      Modis.redis_options = options if client == :redis
    end

    def set_defaults
      self.push_poll = 2
      self.feedback_poll = 60
      self.batch_size = 100
      self.logger = nil
      self.log_file = 'log/rpush.log'
      self.pid_file = 'tmp/rpush.pid'
      self.log_level = (defined?(Rails) && Rails.logger) ? Rails.logger.level : ::Logger::Severity::INFO
      self.plugin = OpenStruct.new

      # Internal options.
      self.embedded = false
      self.push = false
    end

    def initialize_client
      return if @client_initialized
      raise ConfigurationError, 'Rpush.config.client is not set.' unless client
      require "rpush/client/#{client}"
      client_module = Rpush::Client.const_get(client.to_s.camelize)
      Rpush.send(:include, client_module)

      [:Apns, :Gcm, :Wpns, :Adm].each do |service|
        Rpush.const_set(service, client_module.const_get(service))
      end

      @client_initialized = true
    end
  end
end
