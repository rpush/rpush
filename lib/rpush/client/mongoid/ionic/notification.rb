module Rpush
  module Client
    module Mongoid
      module Ionic
        class Notification < Rpush::Client::Mongoid::Notification
          include Rpush::Client::ActiveModel::Ionic::Notification
        end
      end
    end
  end
end
