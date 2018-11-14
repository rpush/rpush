module Rpush
  module VERSION
    MAJOR = 3
    MINOR = 3
    TINY = 1
    PRE = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".").freeze

    def self.to_s
      STRING
    end
  end
end
