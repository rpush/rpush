module Rpush
  module Client
    module Mongoid
      module Wns
        class BadgeNotification < Rpush::Client::Mongoid::Notification
          include Rpush::Client::ActiveModel::Wns::Notification

          def skip_data_validation?
            true
          end
        end
      end
    end
  end
end
