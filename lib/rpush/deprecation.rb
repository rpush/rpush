module Rpush
  class Deprecation
    def self.muted
      begin
        orig_val = Thread.current[:rpush_mute_deprecations]
        Thread.current[:rpush_mute_deprecations] = true
        yield
      ensure
        Thread.current[:rpush_mute_deprecations] = orig_val
      end
    end

    def self.muted?
      Thread.current[:rpush_mute_deprecations] == true
    end

    def self.warn(msg)
      unless Rpush::Deprecation.muted?
        STDERR.puts "DEPRECATION WARNING: #{msg}"
      end
    end
  end
end
