module Rpush
  def self.push(options = {})
    require 'rpush/daemon'

    config = Rpush::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.push = true
    Rpush.config.update(config)

    Rpush::Daemon.common_init
    Rpush::Daemon::Synchronizer.sync
    Rpush::Daemon::Feeder.start
    # TODO: Wait until there are no more notifications.
    Rpush::Daemon::AppRunner.stop
  end
end
