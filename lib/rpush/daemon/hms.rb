module Rpush
  module Daemon
    module Hms
      extend ServiceConfigMethods

      dispatcher :hms_http, token_provider: Rpush::Daemon::Hms::Token
    end
  end
end
