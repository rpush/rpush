module Rpush
  module Client
    module Redis
      module Apnsp8
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Apnsp8::Notification
        end
      end
    end
  end
end
