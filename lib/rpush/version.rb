module Rpush
  module VERSION
    MAJOR = 3
    MINOR = 0
    TINY = 0
    PRE = 'rc1'.freeze

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".").freeze

    def self.to_s
      STRING
    end
  end
end
