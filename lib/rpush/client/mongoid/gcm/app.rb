module Rpush
  module Client
    module Mongoid
      module Gcm
        class App < Rpush::Client::Mongoid::App
          include Rpush::Client::ActiveModel::Gcm::App
        end
      end
    end
  end
end
