# frozen_string_literal: true

module Rpush
  def self.embed
    require 'rpush/daemon'

    $stderr.puts 'Rpush.embed can only be run once inside this process.' if @embed_thread

    Rpush.config.embedded = true
    Rpush.config.foreground = true
    Kernel.at_exit { shutdown }
    @embed_thread = Thread.new { Rpush::Daemon.start }
  end

  def self.shutdown
    return unless Rpush.config.embedded

    Rpush::Daemon.shutdown
    @embed_thread&.join
  rescue StandardError => e
    $stderr.puts(e.message)
    $stderr.puts(e.backtrace.join("\n"))
  ensure
    @embed_thread = nil
  end

  def self.sync
    return unless Rpush.config.embedded

    Rpush::Daemon::Synchronizer.sync
  end

  def self.status
    return unless Rpush.config.embedded

    status = Rpush::Daemon::AppRunner.status
    Rpush.logger.info(JSON.pretty_generate(status))
    status
  end

  def self.debug
    status
  end
end
