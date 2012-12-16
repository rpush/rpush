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

    def initialize(klass, method_name, version, msg)
      klass.instance_eval do
        alias_method "#{method_name}_without_warning", method_name
      end
      warning = "#{method_name} is deprecated and will be removed from Rapns #{version}."
      warning << " #{msg}" if msg
      klass.class_eval(<<-RUBY, __FILE__, __LINE__)
        def #{method_name}(*args, &blk)
          unless Rapns::Deprecation.silenced?
            STDERR.puts "DEPRECATION WARNING: #{warning}"
          end
          #{method_name}_without_warning(*args, &blk)
        end
      RUBY
    end
  end
end
