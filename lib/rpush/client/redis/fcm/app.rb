module Rpush
  module Client
    module Redis
      module Fcm
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Fcm::App
        end
      end
    end
  end
end
