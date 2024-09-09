# frozen_string_literal: true

module Rpush
  module Daemon
    module Fcm
      extend ServiceConfigMethods

      dispatcher :http
    end
  end
end
