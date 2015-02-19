module Rpush
  def self.embed(options = {})
    require 'rpush/daemon'

    unless options.empty?
      warning = "Passing configuration options directly to Rpush.embed is deprecated and will be removed from Rpush 2.5.0. Please setup configuration using Rpush.configure { |config| ... } before calling embed."
      Rpush::Deprecation.warn_with_backtrace(warning)
    end

    if @embed_thread
      STDERR.puts 'Rpush.embed can only be run once inside this process.'
    end

    config = Rpush::ConfigurationWithoutDefaults.new
    options.each { |k, v| config.send("#{k}=", v) }
    config.embedded = true
    config.foreground = true
    Rpush.config.update(config)
    Kernel.at_exit { shutdown }
    @embed_thread = Thread.new { Rpush::Daemon.start }
  end

  def self.shutdown
    return unless Rpush.config.embedded
    Rpush::Daemon.shutdown
    @embed_thread.join if @embed_thread
  rescue StandardError => e
    STDERR.puts(e.message)
    STDERR.puts(e.backtrace.join("\n"))
  ensure
    @embed_thread = nil
  end

  def self.sync
    return unless Rpush.config.embedded
    Rpush::Daemon::Synchronizer.sync
  end

  def self.debug
    return unless Rpush.config.embedded
    Rpush::Daemon::AppRunner.debug
  end
end
