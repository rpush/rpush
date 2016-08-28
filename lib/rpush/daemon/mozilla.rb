require 'rpush'
require 'rpush/daemon'

module Rpush
  module Daemon
    module Mozilla
      extend ServiceConfigMethods

      dispatcher :http
    end
  end
end
