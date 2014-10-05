module Rpush
  module Agent
    @id = SecureRandom.uuid
    attr_reader :id
  end
end
