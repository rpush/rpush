module Rpush
  module Client
    module ActiveModel
      module Apns2
        include Rpush::Client::ActiveModel::Apns

        MAX_PAYLOAD_BYTESIZE = 4096
      end
    end
  end
end
