module Rpush
  module Client
    module Mongoid
      module Wns
        class Notification < Rpush::Client::Mongoid::Notification
          include Rpush::Client::ActiveModel::Wns::Notification
        end
      end
    end
  end
end
