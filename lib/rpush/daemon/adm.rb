# frozen_string_literal: true

module Rpush
  module Daemon
    module Adm
      extend ServiceConfigMethods

      dispatcher :http
    end
  end
end
