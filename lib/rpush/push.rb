module Rpush
  def self.push(options = {})
    Rpush.require_for_daemon

    config = Rpush::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.push = true
    Rpush.config.update(config)

    Upgraded.check(:exit => false)
    Rpush::Daemon.initialize_store
    Rpush::Daemon::AppRunner.sync
    Rpush::Daemon::Feeder.start
    Rpush::Daemon::AppRunner.wait
    Rpush::Daemon::AppRunner.stop
  end
end
