module Rpush
  module Client
    module Mongoid
      module Wns
        class RawNotification < Rpush::Client::Mongoid::Notification
          include Rpush::Client::ActiveModel::Wns::Notification
        end
      end
    end
  end
end
