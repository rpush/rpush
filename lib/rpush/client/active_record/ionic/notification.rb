module Rpush
  module Client
    module ActiveRecord
      module Ionic
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Ionic::Notification
        end
      end
    end
  end
end
