module Rpush
  module Client
    module ActiveRecord
      module Ionic
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Ionic::App
        end
      end
    end
  end
end
