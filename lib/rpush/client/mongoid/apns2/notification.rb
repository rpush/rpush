module Rpush
  module Client
    module Mongoid
      module Apns2
        class Notification < Rpush::Client::Mongoid::Notification
          include Rpush::Client::ActiveModel::Apns2::Notification
        end
      end
    end
  end
end
