module Rpush
  module Client
    module Mongoid
      module Wns
        class App < Rpush::Client::Mongoid::App
          include Rpush::Client::ActiveModel::Wns::App

          field :access_token, type: String
          field :access_token_expiration, type: Time
        end
      end
    end
  end
end
