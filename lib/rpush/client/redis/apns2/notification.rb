module Rpush
  module Client
    module Redis
      module Apns2
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Apns2::Notification

          def max_payload_bytesize
            Rpush::Client::ActiveModel::Apns2::MAX_PAYLOAD_BYTESIZE
          end
        end
      end
    end
  end
end
