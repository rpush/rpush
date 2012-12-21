module Rapns
  def self.embed(options = {})
    Rapns.require_for_daemon

    config = Rapns::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.embedded = true
    Rapns.config.update(config)
    Rapns::Daemon.start

    Kernel.at_exit { shutdown }
  end

  def self.shutdown
    return unless Rapns.config.embedded
    Rapns::Daemon.shutdown
  end

  def self.sync
    return unless Rapns.config.embedded
    Rapns::Daemon::AppRunner.sync
  end

  def self.debug
    return unless Rapns.config.embedded
    Rapns::Daemon::AppRunner.debug
  end
end
