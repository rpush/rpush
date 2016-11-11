module Rpush
  module Daemon
    module Apns2
      extend ServiceConfigMethods

      dispatcher :apns_http2
    end
  end
end
