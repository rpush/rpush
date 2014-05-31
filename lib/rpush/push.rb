module Rpush
  def self.push(options = {})
    Rpush.require_for_daemon

    config = Rpush::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.push = true
    Rpush.config.update(config)

    Rpush::Daemon.initialize_store
    Rpush::Daemon::AppRunner.sync
    Rpush::Daemon::Feeder.start
    sleep 0.1 while Rpush::Daemon::AppRunner.cumulative_queue_size > 0
    Rpush::Daemon::AppRunner.stop
  end
end
