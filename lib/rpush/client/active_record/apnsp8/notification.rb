module Rpush
  module Client
    module ActiveRecord
      module Apnsp8
        class Notification < Rpush::Client::ActiveRecord::Apns2::Notification
          include Rpush::Client::ActiveModel::Apns2::Notification
        end
      end
    end
  end
end
