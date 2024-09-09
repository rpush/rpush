module Rpush
  module Client
    module ActiveRecord
      module Hms
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Hms::Notification
        end
      end
    end
  end
end
