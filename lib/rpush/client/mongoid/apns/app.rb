module Rpush
  module Client
    module Mongoid
      module Apns
        class App < Rpush::Client::Mongoid::App
          include Rpush::Client::ActiveModel::Apns::App
        end
      end
    end
  end
end
