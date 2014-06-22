module Rpush
  module Client
    module Redis
      module Apns
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Apns::Notification

          def alert=(alert)
            alert = alert.to_s unless alert.kind_of?(Hash)
            super
          end
        end
      end
    end
  end
end
