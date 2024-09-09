# frozen_string_literal: true

module Rpush
  module Client
    module Redis
      module Wpns
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Wpns::App
        end
      end
    end
  end
end
