module Rapns
  def self.push(options = {})
    Rapns.require_for_daemon

    config = Rapns::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.push = true
    Rapns.config.update(config)

    Upgraded.check(:exit => false)
    Rapns::Daemon.initialize_store
    Rapns::Daemon::AppRunner.sync
    Rapns::Daemon::Feeder.start
    Rapns::Daemon::AppRunner.wait
    Rapns::Daemon::AppRunner.stop
  end
end
