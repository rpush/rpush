module Rpush
  module Client
    module ActiveRecord
      module Apns2
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Apns2::Notification
          include ActiveRecordSerializableNotification
        end
      end
    end
  end
end
