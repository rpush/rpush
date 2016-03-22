require 'rpush'
require 'rpush/daemon'

module Rpush
  module Daemon
    module Firefox
      extend ServiceConfigMethods

      dispatcher :http
    end
  end
end
