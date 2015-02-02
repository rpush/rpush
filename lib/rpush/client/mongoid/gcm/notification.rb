module Rpush
  module Client
    module Mongoid
      module Gcm
        class Notification < Rpush::Client::Mongoid::Notification
          include Rpush::Client::ActiveModel::Gcm::Notification
        end
      end
    end
  end
end
