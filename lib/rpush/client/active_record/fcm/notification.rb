module Rpush
  module Client
    module ActiveRecord
      module Fcm
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Fcm::Notification
        end
      end
    end
  end
end
