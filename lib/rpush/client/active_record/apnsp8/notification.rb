module Rpush
  module Client
    module ActiveRecord
      module Apnsp8
        class Notification < Rpush::Client::ActiveRecord::Apns::Notification
          include Rpush::Client::ActiveModel::Apns::Notification
        end
      end
    end
  end
end
