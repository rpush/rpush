module Rapns
  class Deprecation
    def self.silenced
      begin
        Thread.current[:rapns_silence_deprecations] = true
        yield
      ensure
        Thread.current[:rapns_silence_deprecations] = false
      end
    end

    def self.silenced?
      Thread.current[:rapns_silence_deprecations]
    end

    def self.warn(msg)
      unless Rapns::Deprecation.silenced?
        STDERR.puts "DEPRECATION WARNING: #{msg}"
      end
    end
  end
end
