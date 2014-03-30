module Rpush
  module Client
    module Redis
      module Adm
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Adm::App
        end
      end
    end
  end
end
