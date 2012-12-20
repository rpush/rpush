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
    Rapns::Daemon.shutdown
  end

  def self.sync
    Rapns::Daemon::AppRunner.sync
  end

  def self.debug
    Rapns::Daemon::AppRunner.debug
  end
end
