module Rpush
  module Client
    module ActiveRecord
      module Apns2
        class Notification < Rpush::Client::ActiveRecord::Apns::Notification
          def max_payload_bytesize
            Rpush::Client::ActiveModel::Apns2::MAX_PAYLOAD_BYTESIZE
          end
        end
      end
    end
  end
end
