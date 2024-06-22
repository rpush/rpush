module Rpush
  module Client
    module Redis
      module Fcm
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Fcm::Notification
        end
      end
    end
  end
end
