module Rpush
  module VERSION
    MAJOR = 3
    MINOR = 2
    TINY = 2
    PRE = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".").freeze

    def self.to_s
      STRING
    end
  end
end
