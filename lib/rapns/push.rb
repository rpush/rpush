module Rapns
  def self.push(options = {})
    Rapns.require_for_daemon

    config = Rapns::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.push = true
    Rapns.config.reset
    Rapns.config.update(config)
    Rapns::Daemon.start
    Rapns::Daemon.shutdown(true)
  end
end
