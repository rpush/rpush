module Rpush
  module Client
    module Mongoid
      module Wpns
        class App < Rpush::Client::Mongoid::App
          include Rpush::Client::ActiveModel::Wpns::App
        end
      end
    end
  end
end
