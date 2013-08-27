module Rapns
  class Deprecation
    def self.muted
      begin
        orig_val = Thread.current[:rapns_mute_deprecations]
        Thread.current[:rapns_mute_deprecations] = true
        yield
      ensure
        Thread.current[:rapns_mute_deprecations] = orig_val
      end
    end

    def self.muted?
      Thread.current[:rapns_mute_deprecations] == true
    end

    def self.warn(msg)
      unless Rapns::Deprecation.muted?
        STDERR.puts "DEPRECATION WARNING: #{msg}"
      end
    end
  end
end
