module Rpush
  module Client
    module Mongoid
      module Apns2
        class App < Rpush::Client::Mongoid::Apns::App
          include Rpush::Client::ActiveModel::Apns2::App
        end
      end
    end
  end
end
