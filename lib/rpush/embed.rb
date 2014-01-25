module Rpush
  def self.embed(options = {})
    Rpush.require_for_daemon

    config = Rpush::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.embedded = true
    Rpush.config.update(config)
    Rpush::Daemon.start

    Kernel.at_exit { shutdown }
  end

  def self.shutdown
    return unless Rpush.config.embedded
    Rpush::Daemon.shutdown
  end

  def self.sync
    return unless Rpush.config.embedded
    Rpush::Daemon::AppRunner.sync
  end

  def self.debug
    return unless Rpush.config.embedded
    Rpush::Daemon::AppRunner.debug
  end
end
