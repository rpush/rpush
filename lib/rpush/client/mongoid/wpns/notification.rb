module Rpush
  module Client
    module Mongoid
      module Wpns
        class Notification < Rpush::Client::Mongoid::Notification
          include Rpush::Client::ActiveModel::Wpns::Notification
        end
      end
    end
  end
end
