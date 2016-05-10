module Rpush
  module Client
    module Redis
      module Ionic
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Ionic::Notification
        end
      end
    end
  end
end
