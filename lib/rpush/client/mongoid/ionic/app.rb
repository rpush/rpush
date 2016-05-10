module Rpush
  module Client
    module Mongoid
      module Ionic
        class App < Rpush::Client::Mongoid::App
          include Rpush::Client::ActiveModel::Ionic::App
        end
      end
    end
  end
end
