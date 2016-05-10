module Rpush
  module Client
    module Redis
      module Ionic
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Ionic::App
        end
      end
    end
  end
end
