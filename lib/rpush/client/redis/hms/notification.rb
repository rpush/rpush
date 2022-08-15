module Rpush
  module Client
    module Redis
      # required app_id
      # required title
      # required body
      # required click_action
      # required tokens
      module Hms
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Hms::Notification
        end
      end
    end
  end
end
