# frozen_string_literal: true

module Rpush
  module Daemon
    module Webpush
      extend ServiceConfigMethods

      dispatcher :http
    end
  end
end
