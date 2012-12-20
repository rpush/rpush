module Rapns
  def self.embed(options = {})
    Rapns.require_for_daemon

    config = Rapns::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.embedded = true
    Rapns.config.update(config)
    Rapns::Daemon.start
  end

  def self.shutdown
    Rapns::Daemon.shutdown
  end
end
