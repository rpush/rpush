module Rpush
  module MultiJsonHelper
    def multi_json_load(string, options = {})
      return ::MultiJSON.parse(string, options) if defined?(::MultiJSON)

      # Calling load on multi_json less than v1.3.0 attempts to load a file from disk.
      if Gem.loaded_specs['multi_json'].version >= Gem::Version.create('1.3.0')
        MultiJson.load(string, options)
      else
        MultiJson.decode(string, options)
      end
    end

    def multi_json_dump(string, options = {})
      return ::MultiJSON.generate(string, options) if defined?(::MultiJSON)

      MultiJson.respond_to?(:dump) ? MultiJson.dump(string, options) : MultiJson.encode(string, options)
    end
  end
end
