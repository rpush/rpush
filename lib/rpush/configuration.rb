module Rpush
  def self.config
    @config ||= Rpush::Configuration.new
  end

  def self.configure
    if block_given?
      yield config
      initialize_client
    end
  end

  def self.initialize_client
    return if @client_initialized
    require "rpush/client/#{config.client}"
    client_module = Rpush::Client.const_get(config.client.to_s.camelize)
    Rpush.send(:include, client_module)

    [:Apns, :Gcm, :Wpns, :Adm].each do |service|
      Rpush.const_set(service, client_module.const_get(service))
    end

    @client_initialized = true
  end

  CONFIG_ATTRS = [:foreground, :push_poll, :feedback_poll, :embedded,
    :check_for_errors, :pid_file, :batch_size, :push, :client, :logger,
    :batch_storage_updates, :wakeup, :log_dir]

  class ConfigurationWithoutDefaults < Struct.new(*CONFIG_ATTRS)
  end

  class Configuration < Struct.new(*CONFIG_ATTRS)
    include Deprecatable

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
        super(File.join(Rails.root, path))
      else
        super
      end
    end

    def logger=(logger)
      super(logger)
    end

    def foreground=(bool)
      if Rpush.jruby?
        # The JVM does not support fork().
        super(true)
      else
        super
      end
    end

    def set_defaults
      if Rpush.jruby?
        # The JVM does not support fork().
        self.foreground = true
      else
        self.foreground = false
      end

      self.push_poll = 2
      self.feedback_poll = 60
      self.check_for_errors = 0.2
      self.batch_size = 100
      self.pid_file = nil
      self.client = :active_record
      self.logger = nil
      self.batch_storage_updates = true
      self.log_dir = Rails.root

      # Internal options.
      self.embedded = false
      self.push = false
    end
  end
end
