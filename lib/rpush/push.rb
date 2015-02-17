module Rpush
  def self.push(options = {})
    require 'rpush/daemon'

    unless options.empty?
      warning = "Passing configuration options directly to Rpush.push is deprecated and will be removed from Rpush 2.5.0. Please setup configuration using Rpush.configure { |config| ... } before calling push."
      Rpush::Deprecation.warn_with_backtrace(warning)
    end

    config = Rpush::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.push = true
    Rpush.config.update(config)

    Rpush::Daemon.common_init
    Rpush::Daemon::Synchronizer.sync
    Rpush::Daemon::Feeder.start(true) # non-blocking
    Rpush::Daemon::AppRunner.stop
  end
end
